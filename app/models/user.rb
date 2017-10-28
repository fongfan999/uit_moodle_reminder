require 'mechanize'

class User < ApplicationRecord
  CALENDER_PAGE = 'https://courses.uit.edu.vn/calendar/view.php?lang=en'
  COURSE_EXCEPTION = [
    'Các cuộc thi của Đoàn Thanh niên', 'Ý tưởng sáng tạo 2016'
  ]
  MILESTONES = [3.days, 1.day, 30.minutes]

  has_secure_token

  has_many :reminders, dependent: :delete_all
  has_many :events, through: :reminders

  after_create :subscribe
  after_update :subscribe_notifier, if: :sender_id_changed?
  before_save :encrypt_password
  after_save :decrypt_password
  after_find :decrypt_password

  def self.find_by_username_or_initialize_by(params)
    where(username: params[:username]).first_or_initialize(params)
  end

  def self.fetch_new_events
    User.all.each(&:subscribe)
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

    if page.uri.to_s == ENV['HOMEPAGE']
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

  def subscribe_notifier
    HTTParty.post(ENV['NOTIFIER_URL'],
      headers: {
        "Authorization": "Token token=#{ENV['NOTIFIER_TOKEN']}"
      },
      body: {
        user: {
          username: self.username,
          password: self.password,
          sender_id: self.sender_id
        }
      }
    )
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
    unless page.uri.to_s == ENV['HOMEPAGE']
      UserMailer.cannot_login(self).deliver_now
      self.unsubscribe
    end

    # Scrap upcoming events
    agent.get(CALENDER_PAGE).search('.event').each do |e|
      next if COURSE_EXCEPTION.include?( course = e.at('.course').text )

      date = e.at('.date').text.sub(/Tomorrow, /, '')
      date = Time.zone.parse(date).tomorrow if date.length == 5
      next if date < Time.zone.now

      referer = e.at('.referer')
      event_params = {
        referer: referer.text,
        course: course,
        date: date,
        description: e.at('.description').text,
        link: referer.at('a').attr('href')
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
    self.jobs(event).delete_all
  end

  def jobs(event = nil)
    if event.nil?
      Delayed::Job.where('handler LIKE ?', "%username: '#{self.username}'%")
    else
      Delayed::Job.where('handler LIKE ?', "%username: '#{self.username}'%")
        .where(
          'handler LIKE ? OR handler LIKE ?',
          "%referer: #{event.referer}%",
          "%send_reminder\n  - '#{event.id}'%"
        )
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
      page = agent.get(ENV['HOMEPAGE'])
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
    handle_asynchronously :subscribe_notifier, priority: 4
end
