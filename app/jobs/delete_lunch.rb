class DeleteLunch
  attr_reader :channel_id, :user_id, :message, :client
  def initialize(channel_id, user_id, message, client = Slack::Web::Client.new)
    @channel_id = channel_id
    @user_id = user_id
    @message = message
    @client = client
  end

  #we still need to handle the case where they supply a time stamp/
  #do we make it interactive (list the lunches in the reply and let them pick)?
  #or do we make them specify a timestamp
  def perform
    groups = base_query

    if groups.size > 1
      lunchtimes = groups.map(&:departure_time)
      prompt_for_lunchtime(lunchtimes)
      CommandResult.new(
        "If you'd like to make a call, please hang up and try again.",
        false
      )
    elsif groups.size == 1
      groups.first.destroy
      CommandResult.new(
        "The world is a little bit darker place this day.",
        true
      )
    else
      CommandResult.new(
        "You don't seem to have any open lunch groups",
        false
      )
    end
  end

  def prompt_for_lunchtime(lunchtimes)
    timezone = SlackUser.new(user_id).timezone(client)
    picker = LunchtimePicker.generate(lunchtimes, timezone, "delete-picked-lunch")
    client.chat_postEphemeral(channel: channel_id,
                              user: user_id,
                              text: "You have more than one open lunch request.  Which one would you like to mercilessly destroy?",
                              as_user: true,
                              blocks: picker
                             )

  end

  private
  def base_query
    if message.blank?
      LunchGroup.where(
        initiating_user_id: user_id,
        channel_id: channel_id,
        status: 'open'
      )
    else
      LunchGroup.where(
        initiating_user_id: user_id,
        channel_id: channel_id,
        departure_time: message,
        status: 'open'
      )
    end
  end

end


class CommandResult < Struct.new(:message, :succeeded?); end
