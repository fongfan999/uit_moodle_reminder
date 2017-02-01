require 'mechanize'

class User < ApplicationRecord
  HOMEPAGE = 'https://courses.uit.edu.vn/'
  CALENDER_PAGE = 'https://courses.uit.edu.vn/calendar/view.php?lang=en'
  MILESTONES = [1.week, 3.days, 1.day, 2.hours, 30.minutes]

  has_secure_token

  has_many :reminders
  has_many :events, through: :reminders

  after_create :subscribe_moodle

  def self.find_by_username_or_initialize_by(params)
    where(username: params[:username]).first_or_initialize(params)
  end

  def self.fetch_new_events
    User.all.each do |user|
      user.subscribe_moodle
    end
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
    page.uri.to_s == HOMEPAGE
  end

  def assign_to_reminders(event)
    # user.milestones might is available in the future
    MILESTONES.each do |milestone|
      if Time.zone.now < event.date - milestone
        UserMailer.delay(run_at: event.date - milestone)
          .upcoming_event(self, event, User.milestone_to_time_left(milestone))
      end
    end
  end

  def subscribe_moodle
    # Login
    agent = login_to_moodle

    # Scrap upcoming events
    agent.get(CALENDER_PAGE).search('.event').each do |e|
      event_params = {
        referer: e.search('.referer').text,
        course: e.search('.course').text,
        date: e.search('.date').text,
        description: e.search('.description').text
      }

      event = Event.find_without_by_date_or_initialize_by(event_params)
      event.save(validate: false) if event.new_record?

     # Handle asynchronously mailer
      unless event.users.include?(self)
        event.users << self
        assign_to_reminders(event)
      end
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

  handle_asynchronously :subscribe_moodle, priority: 5
end
