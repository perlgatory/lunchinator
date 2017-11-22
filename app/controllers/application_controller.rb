class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    client = Slack::Web::Client.new
    channel_id = params[:channel_id]
    initiating_user_id = params[:user_id]
    user_time_zone = get_user_timezone(initiating_user_id, client)
    app_text = params[:text].empty? ? 'noon' : params[:text]
    parsed_time = Chronic.parse(app_text.strip.gsub(/^\s*(at|@)\s+/i, ''))
    if parsed_time.nil?
      render plain: "'#{parsed_time}' is an invalid time. Please specify a time to go to lunch."
      return
    end
    lunch_time = ActiveSupport::TimeZone.new(user_time_zone).local_to_utc(parsed_time).in_time_zone(user_time_zone)
    now = Time.now.in_time_zone(user_time_zone)
    if lunch_time < now
      render plain: "#{parsed_time} is in the past. Please pick a different time for lunch... or build a time machine."
      return
    elsif lunch_time < now + 10.minutes
      assemble_time = lunch_time
    elsif lunch_time < now + 20.minutes
      assemble_time = now + 10.minutes
    else
      assemble_time = lunch_time - 10.minutes
    end
    channel = Channel.new(channel_id)
    status = channel.client_status(client)
    if status == :already_joined
      resp = client.chat_postMessage(channel: channel_id,
                              text: "#{app_text} (#{lunch_time.strftime('%H:%M (%Z)')}), who is in for lunch? (react with :+1: by #{assemble_time.strftime('%H:%M (%Z)')})",
                              as_user: true)
      response_ts = resp.message.ts
      client.reactions_add(name: '+1', channel: channel_id, timestamp: response_ts)
      CreateGroup
        .set(wait_until: assemble_time)
        .perform_later(channel_id, initiating_user_id, response_ts)
      render plain: 'lunch? that sounds good!'
    elsif status == :not_joined
      render plain: "Looks like I'm not invited :cry:. Please invite me to the channel!"
    else
      render plain: "I'm not allowed in there :slightly_frowning_face:"
    end
  end

  def get_user_timezone(user_id, client)
    # https://api.slack.com/methods/users.info <- get user timezone from here
    user_response = client.users_info(user: user_id)
    # check that response is good
    status_ok = user_response.ok
    unless status_ok
      return :not_ok # TODO: Handle this
    end
    user_response.user.tz
  end
end
