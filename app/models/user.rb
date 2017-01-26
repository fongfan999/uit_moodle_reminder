require 'mechanize'

class User < ApplicationRecord
  HOMEPAGE = 'https://courses.uit.edu.vn/'

  has_and_belongs_to_many :events

  after_create :subscribe_moodle

  def self.find_by_username_or_initialize_by(params)
    where(username: params[:username]).first_or_initialize(params)
  end

  def self.fetch_new_events!
    User.all.each do |user|
      user.fetch_new_self_events!
    end
  end

  def email
    username + '@gm.uit.edu.vn'
  end

  def is_authenticated?
    return false if (username.blank? || password.blank?)

    login_to_moodle!.uri.to_s == HOMEPAGE
  end

  # def fetch_new_self_events!
  #   # Login
  #   agent = Mechanize.new
  #   page = agent.get(HOMEPAGE)
  #   agent.page.encoding = 'utf-8'
  #   moodle_form = page.forms.last

  #   moodle_form.username = username
  #   moodle_form.password = password
  #   agent.submit(moodle_form)
  #   # End login

  #   # Scrap upcoming events
  #   agent.get('https://courses.uit.edu.vn/calendar/view.php?lang=en')
  #     .search('.event').each do |event|
  #       event_params = {
  #         referer: event.search('.referer').text,
  #         course: event.search('.course').text,
  #         date: event.search('.date').text,
  #         description: event.search('.description').text
  #       }

  #       event = Event.find_without_by_date_or_initialize_by(event_params)
  #       event.save(validate: false) if event.new_record?
  #       event.users << self
  #     end
  # end


  private

  def login_to_moodle!
    agent = Mechanize.new
    page = agent.get(HOMEPAGE)
    agent.page.encoding = 'utf-8'
    moodle_form = page.forms.last

    moodle_form.username = username
    moodle_form.password = password

    agent.submit(moodle_form)
  end

  def subscribe_moodle
    # Login
    agent = Mechanize.new
    page = agent.get(HOMEPAGE)
    agent.page.encoding = 'utf-8'
    moodle_form = page.forms.last

    moodle_form.username = username
    moodle_form.password = password
    agent.submit(moodle_form)
    # End login

    # Scrap upcoming events
    agent.get('https://courses.uit.edu.vn/calendar/view.php?lang=en')
      .search('.event').each do |e|
        event_params = {
          referer: e.search('.referer').text,
          course: e.search('.course').text,
          date: e.search('.date').text,
          description: e.search('.description').text
        }

        event = Event.find_without_by_date_or_initialize_by(event_params)
        event.save(validate: false) if event.new_record?
        event.users << self

        UserMailer.upcoming_event(self, event).deliver_now
      end
  end
end
