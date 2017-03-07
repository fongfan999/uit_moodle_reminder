require 'mechanize'

class Notification < ApplicationRecord
  OFF_CLASS_PAGE = 'https://daa.uit.edu.vn/thong-bao-nghi-bu'

  def self.clean
    ids = Notification.pluck(:id, :title)
      .find_all { |id, title| Time.zone.parse(title) < Time.zone.now }
      .map(&:first)

    Notification.delete(ids)
  end

  def self.fetch_new_notifications
    agent = Mechanize.new
    (0..9).each do |page|
      agent.get(OFF_CLASS_PAGE + "?page=#{page}")
            .search('.views-row').each do |n|
        title_with_link = n.at('h2 a')
        notification_params = {
          title: title_with_link.text,
          content: n.at('.content').text.strip,
          link: "https://daa.uit.edu.vn#{title_with_link.attr('href')}"
        }

        notification = Notification.find_or_initialize_by(notification_params)
        if notification.new_record? && 
            Time.zone.parse(notification.title) > Time.zone.now
          notification.save(validate: false)
          if course = Course.belongs_to(notification)
            course.users.each do |user|
              MessengerCommand.new(
                {"id" => user.sender_id},
                "ff send_notification #{notification.id}"
              ).delay.execute
            end
          end
        end
      end
    end
  end
end
