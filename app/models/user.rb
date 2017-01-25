require 'mechanize'

class User < ApplicationRecord
  def self.find_by_username_or_initialize_by(params)
    where(username: params[:username]).first_or_initialize(params)
  end
  def email
    username + '@gm.uit.edu.vn'
  end

  def is_authenticated?
    return false if (username.blank? || password.blank?)

    moodle_homepage = 'https://courses.uit.edu.vn/'
    agent = Mechanize.new
    page = agent.get(moodle_homepage)
    agent.page.encoding = 'utf-8'
    moodle_form = page.forms.last

    moodle_form.username = username
    moodle_form.password = password
    page = agent.submit(moodle_form)

    page.uri.to_s == moodle_homepage
  end
end
