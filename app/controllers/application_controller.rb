class ApplicationController < ActionController::Base
  def test
    render plain: "How'd you get here? Shoo!"
  end

  def lunch
    client = Slack::Web::Client.new
    channel_id = params[:channel_id]
    initiating_user = SlackUser.new(params[:user_id])
    user_time_zone = get_user_timezone(initiating_user.id, client)

    (user_time, user_place) = parse_lunch_command_payload(params[:text])

    parsed_time = Chronic.parse("today " + user_time)
    if parsed_time.nil?
      render plain: "'#{params[:text]}' is an invalid time. Please specify a time to go to lunch."
      return
    end
    lunch_time = ActiveSupport::TimeZone.new(user_time_zone).local_to_utc(parsed_time).in_time_zone(user_time_zone)

    # check if departure time to the same destination (if any) is within 30 minutes and status is open
    results = LunchGroup.where(departure_time: (lunch_time - 30.minutes)..(lunch_time + 30.minutes), destination: user_place, status: 'open').to_a
    # filter results for those with a channel_id that user can access
    results.select! do |item|
        members_response = client.conversations_members(channel: item.channel_id, limit: 999)
        members = members_response.members
        while !(next_cursor = members_response.response_metadata.next_cursor).blank?
            members_response = client.conversations_members(channel: item.channel_id, limit: 999, cursor: next_cursor)
            members.concat members_response.members
        end
        members.include? initiating_user.id
    end
    if results.any?
      links = results.map do |item|
        client.chat_getPermalink(channel: item.channel_id, message_ts: item.message_id)['permalink']
      end
      # notify user of other valid group(s)
      client.chat_postEphemeral(channel: channel_id,
                                user: initiating_user.id,
                                text: "You're not the first to plan lunch today!  Consider:\n" + links.join("\n"),
                                as_user: true,
                                attachments: [
                                    {
                                        "text": "Wanna create a new lunch group anyway?",
                                        "fallback": "You are unable to create a lunch group",
                                        "callback_id": "lunch_anyway",
                                        "color": "#3AA3E3",
                                        "attachment_type": "default",
                                        "actions": [
                                            {
                                                "name": "yes",
                                                "text": "Yes",
                                                "type": "button",
                                                "value": params[:text].strip
                                            },
                                            {
                                                "name": "no",
                                                "text": "No",
                                                "type": "button",
                                                "value": links.join("\n")
                                            }
                                        ]
                                    }
                                ])
      return
    end
    make_lunch(client, channel_id, initiating_user, user_time, lunch_time, user_place)
  end

  def parse_lunch_command_payload(payload)
    app_text = payload
    cleaned_app_text = app_text.strip.gsub(/^\s*(at|@)\s+/i, '')
    (user_time, user_place) = cleaned_app_text.split(/\s+(?:at|@)\s*/,2)
    user_time ||= 'noon'
    user_time.strip!

    return user_time, user_place
  end

  def make_lunch(client, channel_id, initiating_user, user_lunch_time, lunch_time, lunch_place)
    channel = Channel.new(channel_id)
    status = channel.client_status(client)
    user_time_zone = get_user_timezone(initiating_user.id, client)
    now = Time.now.in_time_zone(user_time_zone)
    assemble_time = get_assemble_time(lunch_time, now)
    if assemble_time.nil?
      return
    end
    if status == :already_joined
      destination = lunch_place || "to go to lunch"
      resp = client.chat_postMessage(channel: channel_id,
                                     text: "#{initiating_user.username} wants #{destination} at #{user_lunch_time}  (#{lunch_time.strftime('%H:%M %Z')}). Are you interested?\nReact with :+1: by #{assemble_time.strftime('%H:%M %Z')}",
                                     as_user: true)
      response_ts = resp.message.ts
      client.reactions_add(name: '+1', channel: channel_id, timestamp: response_ts)
      LunchGroup.create(
        channel_id: channel_id,
        message_id: response_ts,
        departure_time: lunch_time,
        destination: lunch_place,
        status: 'open',
        initiating_user_id: initiating_user.id
      )
      AssembleGroup
          .set(wait_until: assemble_time)
          .perform_later(channel_id, response_ts)
    elsif status == :not_joined
      render plain: "Looks like I'm not invited :cry:. Please invite me to the channel!"
    else
      render plain: "I'm not allowed in there :slightly_frowning_face:"
    end
  end

  def interactive
    payload = JSON.parse params['payload']
    if payload['callback_id'] == 'lunch_anyway'
      lunch_anyway(payload)
    else
      test
    end
  end

  private
  def lunch_anyway(payload)
    if payload['actions'][0]['name'] == 'no'
      links = payload['actions'][0]['value']
      render plain: "Okay, go join another lunch group then:\n" + links
    elsif payload['actions'][0]['name'] == 'yes'
      client = Slack::Web::Client.new
      channel_id = payload['channel']['id']
      initiating_user_id = payload['user']['id']
      initiating_user = SlackUser.new(initiating_user_id)
      app_text = payload['actions'][0]['value']
      (user_lunch_time, user_place) = parse_lunch_command_payload(app_text)
      user_time_zone = get_user_timezone(initiating_user.id, client)
      parsed_time = Chronic.parse(user_lunch_time)
      lunch_time = ActiveSupport::TimeZone.new(user_time_zone).local_to_utc(parsed_time).in_time_zone(user_time_zone)
      make_lunch(client, channel_id, initiating_user, user_lunch_time, lunch_time, user_place)
      render plain: "Lunch group created.  May the odds be ever in your favour!"
    else
      render plain: "How did you get here?"
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
end
