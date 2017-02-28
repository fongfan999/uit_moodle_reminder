require "facebook/messenger"
include Facebook::Messenger

class MessengerCommand
  AVAILABLE_COMMANDS = %w(
    activate whoami list show next unsubscribe destroy help send_reminder 
    send_notification
  )
  FREE_COMMANDS = %w(activate help)
  REQUIRED_ARG_COMMANDS = %w(
    activate show unsubscribe send_reminder send_notification
  )

  def initialize(sender, text)
    @sender = sender # {"id"=>"123456789"} 
    @user = User.find_by(sender_id: @sender["id"])
     
    if @words = text.try(:split) # ff activate
      @ff = @words[0] # ff
      @command = @words[1] # activate, whoami, ...
      @arg = @words[2] # token, index, ...
    end
  end

  def execute
    # Check user status
    not_active and return if @user.nil? && !FREE_COMMANDS.include?(@command)

    if @ff != "ff" || !AVAILABLE_COMMANDS.include?(@command)
      not_found
    elsif REQUIRED_ARG_COMMANDS.include?(@command) && @arg.nil?
      missing_arg
    else
      send(@command)
    end
  end

  def help
    quick_replies = %w(whoami list next) << "show 1"
    send_as_quick_replies("usage: ff <command> [<args>] [--options]", quick_replies)
  end

  def activate
    if @user
      send_as_text("Tài khoản của bạn đã kích hoạt rồi :D")
    elsif user = User.find_by(token: @arg)
      user.update_columns(sender_id: @sender["id"])
      send_as_text("Xin chúc mừng #{user.name}!\nTài khoản của bạn đã kích hoạt thành công")
    else
      send_as_text("Token không hợp lệ. Vui lòng thử lại :(")
    end
  end

  def whoami
    send_as_text("Xin chào #{@user.name}. Tài khoản của bạn được tạo vào #{@user.created_at.strftime('%H:%M, %d-%m-%Y')}")
  end

  def list
    events = @user.upcoming_events
    send_as_text("Hiện bạn đang có #{events.count} deadline")

    events.each_with_index do |event, index|
      send_as_text("##{index + 1} - #{event.referer} - #{event.course} | 📆 #{event.date.strftime('%H:%M, %d-%m-%Y')}\n--------\n#{event.link}")
    end
  end

  def next
    events = @user.upcoming_events
    if events.count.zero?
      send_as_text("Hiện bạn không có deadline nào")
      return 
    end

    event = events.first
    send_as_text("#{event.referer} - #{event.course} | 📆 #{event.date.strftime('%H:%M, %d-%m-%Y')}\n--------\n#{event.link}")
    send_as_text("#{event.description}")
  end

  def show
    index_as_number = @arg.to_i
    events = @user.upcoming_events

    if index_as_number.zero? || index_as_number > events.count
      invalid_index
      return
    end

    event = @user.upcoming_events[index_as_number - 1]
    send_as_text("#{event.referer} - #{event.course} | 📆 #{event.date.strftime('%H:%M, %d-%m-%Y')}\n--------\n#{event.link}")
    send_as_text("#{event.description}")
  end

  def unsubscribe
    index_as_number = @arg.to_i
    events = @user.upcoming_events

    if index_as_number.zero? || index_as_number > events.count
      invalid_index
      return
    end

    event = @user.upcoming_events[index_as_number - 1]
    @user.unsubscribe_event(event)
    send_as_text("Bạn đã ngừng đăng ký nhận thông báo deadline: #{event.referer}")
  end

  def destroy
    if @arg == "--confirm"
      Student.create(@user.attributes.slice("name", "username", "password"))
      UserMailer.unsubscribe_confirmation(@user).deliver_later
      @user.unsubscribe
      send_as_text("Bạn đã ngừng đăng ký nhận tất cả thông báo thành công.")
    else
      send_as_text("Vui lòng gõ 'ff destroy --confirm' để ngừng nhận tất cả thông báo")
    end
  end

  def send_reminder
    event = Event.find_by_id(@arg)
    time_left = @words[3..-1].join(" ")

    if event && !time_left.empty?
      send_as_text("#############\nBạn đang có 1 deadline sắp hết hạn (chỉ còn #{time_left})\n#{event.referer} - #{event.course} | 📆 #{event.date.strftime('%H:%M, %d-%m-%Y')}\n--------\n#{event.link}")
      send_as_text("#{event.description}")
    end
  end

  def send_notification
    if notification = Notification.find_by_id(@arg)
      send_as_text("🔈🔈 #{notification.title}\n--------\n#{notification.content}\n#{notification.link}")
    end
  end

  private

  def not_found
    send_as_text("Command không tìm thấy!!\nGõ 'ff help' để trợ giúp")
  end

  def missing_arg
    send_as_text("Thiếu thông số!!\nGõ 'ff help' để trợ giúp")
  end

  def invalid_index
    send_as_text("Index không hợp lệ hoặc không tồn tại!!\nGõ 'ff list' để xem Index")
  end

  def not_active
    send_as_text("Bạn chưa đăng ký tài khoản hoặc Tài khoản của bạn chưa được kích hoạt. Nếu bạn đã đăng ký, vui lòng mở email mà hệ thống đã gửi và làm theo hướng dẫn.\nTrường hợp không nhận dược email? Vui lòng liên hệ @fongfan999")
  end

  def send_as_text(text)
    # Truncate text if length is long
    text = (text.chars.first(600).join + " ...") if text.length > 600

    Bot.deliver({
      recipient: @sender,
      message: {
        text: text
      }
    }, access_token: ENV['ACCESS_TOKEN'])
  end

  def send_as_quick_replies(text, args)
    quick_replies = []
    args.each do |title|
      quick_replies << {
        content_type: 'text',
        title: "ff #{title}",
        payload: "ff #{title}"
      }
    end

    Bot.deliver({
      recipient: @sender,
      message: ({
        text: text,
        quick_replies: quick_replies
      })
    }, access_token: ENV['ACCESS_TOKEN'])
  end
end

Facebook::Messenger::Thread.set({
  setting_type: 'call_to_actions',
  thread_state: 'existing_thread',
  call_to_actions: [
    {
      type: 'postback',
      title: '☝ Trợ giúp nhanh (ff help)',
      payload: 'ff help'
    },
    {
      type: 'web_url',
      title: '📚  Trợ giúp đầy đủ',
      url: 'https://github.com/fongfan999/uit_moodle_reminder#messenger-cli'
    },
    {
      type: 'web_url',
      title: '🏠  Trang chủ',
      url: 'http://foxfizz.com/'
    },
    {
      type: 'web_url',
      title: '📬  Góp ý, báo lỗi, tâm sự :v',
      url: 'https://m.me/fongfan999'
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])

Bot.on :message do |message|
  message.type
  MessengerCommand.new(message.sender, message.text).execute
end

Bot.on :postback do |postback|
  MessengerCommand.new(postback.sender, postback.payload).execute
end
