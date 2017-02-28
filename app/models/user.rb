require 'mechanize'

class User < ApplicationRecord
  HOMEPAGE = 'https://courses.uit.edu.vn/'
  CALENDER_PAGE = 'https://courses.uit.edu.vn/calendar/view.php?lang=en'
  DAA_HOMEPAGE = 'https://daa.uit.edu.vn/'
  SCHEDULE_PAGE = 'https://daa.uit.edu.vn/sinhvien/thoikhoabieu'
  MILESTONES = [1.week, 3.days, 1.day, 2.hours, 30.minutes]

  has_secure_token

  has_many :reminders, dependent: :delete_all
  has_many :events, through: :reminders
  has_and_belongs_to_many :courses

  after_create :subscribe
  after_create :get_courses
  before_save :encrypt_password
  after_save :decrypt_password
  after_find :decrypt_password

  def self.find_by_username_or_initialize_by(params)
    where(username: params[:username]).first_or_initialize(params)
  end

  def self.fetch_new_events
    User.all.each(&:subscribe)
  end

  def self.get_courses
    User.all.each(&:get_courses)
  end

  def self.milestone_to_time_left(milestone)
    case milestone
    when 1.week
      "1 tuần"
    when 3.days
      "3 ngày"
    when 1.day
      "1 ngày"
    when 2.hours
      "2 giờ"
    else
      "30 phút"
    end
  end

  def email
    username + '@gm.uit.edu.vn'
  end

  def is_authenticated?
    return false if (username.blank? || password.blank?)

    page = login_to_moodle.page

    if page.uri.to_s == HOMEPAGE
      # Assign name
      self.name = page.links.find do |link|
        link.href[/user\/profile\.php/]
      end.text
    end
  end

  def upcoming_events
    events.where("date > ?", Time.zone.now).order(:date)
  end

  def assign_to_reminders(event)
    # user.milestones might is available in the future
    MILESTONES.each do |milestone|
      send_reminder(event, milestone) if Time.zone.now < event.date - milestone
    end
  end

  def get_courses
    return if self.courses.any?
    
    agent = Mechanize.new
    page = agent.get(DAA_HOMEPAGE)
    agent.page.encoding = 'utf-8'

    daa_form = page.forms.last
    daa_form.field_with(name: 'name').value = username
    daa_form.field_with(name: 'pass').value = password
    agent.submit(daa_form)

    agent.get(SCHEDULE_PAGE)
          .search('.rowspan_data strong:first-child').each do |course|
      cc_with_region = course.text
      whitespace_index = cc_with_region.index(" ")
      course = Course.find_or_create_by(
        name: cc_with_region[0..whitespace_index - 1]
      )
      course.users << self unless course.users.include?(self)
    end
  end

  def subscribe
    # unactive user using Messenger
    if messenger? && !sender_id
      delay(run_at: 15.minutes.from_now).subscribe and return 
    end

    # Login
    agent = login_to_moodle
    page = agent.page

    # Failed login
    unless page.uri.to_s == HOMEPAGE
      UserMailer.cannot_login(self).deliver_now
      self.unsubscribe
    end

    # Scrap upcoming events
    agent.get(CALENDER_PAGE).search('.event').each do |e|
      referer = e.search('.referer')
      event_params = {
        referer: referer.text,
        course: e.search('.course').text,
        date: e.search('.date').text,
        description: e.search('.description').text,
        link: referer.search('a').attr('href').value
      }
      event = Event.find_by_link_or_initialize_by(event_params)
      event.save(validate: false)

     # Handle asynchronously mailer
      unless event.users.include?(self)
        event.users << self
        assign_to_reminders(event)
      end
    end
  end

  def unsubscribe
    self.jobs.delete_all
    self.destroy
  end

  def unsubscribe_event(event)
    self.jobs(event.referer).delete_all
  end

  def jobs(event_referer = nil)
    if event_referer.nil?
      Delayed::Job.where('handler LIKE ?', "%username: '#{self.username}'%")
    else
      Delayed::Job.where('handler LIKE ?', "%username: '#{self.username}'%")
        .where('handler LIKE ?', "%referer: #{event_referer}%")
    end
  end

  def send_reminder(event, milestone)
    if messenger?
      MessengerCommand.new({"id" => sender_id}, "ff send_reminder #{event.id} #{User.milestone_to_time_left(milestone)}").delay(run_at: event.date - milestone).execute
    else
      UserMailer.delay(run_at: event.date - milestone)
        .upcoming_event(self, event, User.milestone_to_time_left(milestone))
    end
  end

  private

  def login_to_moodle
    agent = Mechanize.new
    page = agent.get(HOMEPAGE)
    agent.page.encoding = 'utf-8'

    login_form = page.forms.last
    login_form.username = username
    login_form.password = password
    agent.submit(login_form)

    # return agent
    agent
  end

  def encrypt_password
    self.password = AES.encrypt(self.password, Settings.AES_KEY)
  end

  def decrypt_password
    self.password = AES.decrypt(password, Settings.AES_KEY) rescue password
  end

  handle_asynchronously :subscribe, priority: 5
  handle_asynchronously :get_courses, priority: 4
end
