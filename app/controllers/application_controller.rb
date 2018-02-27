class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    client = Slack::Web::Client.new
    channel_id = params[:channel_id]
    initiating_user_id = params[:user_id]
    user_time_zone = get_user_timezone(initiating_user_id, client)
    username = get_username(initiating_user_id)
    app_text = params[:text].empty? ? 'noon' : params[:text]
    cleaned_app_text = app_text.strip.gsub(/^\s*(at|@)\s+/i, '')
    parsed_time = Chronic.parse(cleaned_app_text)
    if parsed_time.nil?
      render plain: "'#{app_text}' is an invalid time. Please specify a time to go to lunch."
      return
    end
    lunch_time = ActiveSupport::TimeZone.new(user_time_zone).local_to_utc(parsed_time).in_time_zone(user_time_zone)
    now = Time.now.in_time_zone(user_time_zone)
    assemble_time = get_assemble_time(lunch_time, now)
    if assemble_time.nil?
      return
    end
    # check if departure time is within 30 minutes and status is open
    results = LunchGroup.where(departure_time: (lunch_time - 30.minutes)..(lunch_time + 30.minutes), status: 'open').to_a
    # filter results for those with a channel_id that user can access TODO: pick up here
    results.select! do |item|
        members_response = client.conversations_members(channel: item.channel_id, limit: 999)
        members = members_response.members
        while !(next_cursor = members_response.response_metadata.next_cursor).blank?
            members_response = client.conversations_members(channel: item.channel_id, limit: 999, cursor: next_cursor)
            members.concat members_response.members
        end
        members.include? initiating_user_id
    end
    if results.any?
      render plain: "Hey, no."
      # notify user of other valid group(s)
      return
    end
    channel = Channel.new(channel_id)
    status = channel.client_status(client)
    if status == :already_joined
      resp = client.chat_postMessage(channel: channel_id,
#                              text: "#{app_text} (#{lunch_time.strftime('%H:%M (%Z)')}), who is in for lunch? (react with :+1: by #{assemble_time.strftime('%H:%M (%Z)')})",
                                     text: "#{username} wants to go to lunch at #{cleaned_app_text} (#{lunch_time.strftime('%H:%M %Z')}). Are you interested?\nReact with :+1: by #{assemble_time.strftime('%H:%M %Z')}",
                                     as_user: true)
      response_ts = resp.message.ts
      client.reactions_add(name: '+1', channel: channel_id, timestamp: response_ts)
      LunchGroup.create(channel_id: channel_id, message_id: response_ts, departure_time: lunch_time, status: 'open')
      AssembleGroup
        .set(wait_until: assemble_time)
        .perform_later(channel_id, initiating_user_id, response_ts)
    elsif status == :not_joined
      render plain: "Looks like I'm not invited :cry:. Please invite me to the channel!"
    else
      render plain: "I'm not allowed in there :slightly_frowning_face:"
    end
  end

  def get_assemble_time(lunch_time, now)
    if lunch_time < now
      render plain: "#{lunch_time} is in the past. Please pick a different time for lunch... or build a time machine."
      nil
    elsif lunch_time < now + 10.minutes
      lunch_time
    elsif lunch_time < now + 20.minutes
      now + 10.minutes
    else
      lunch_time - 10.minutes
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

  def get_username(user_id)
    "<@#{user_id}>"
  end
end
