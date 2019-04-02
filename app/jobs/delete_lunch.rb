class DeleteLunch
  attr_reader :channel_id, :user_id, :message, :client
  def initialize(channel_id, user_id, message, client = Slack::Web::Client.new)
    @channel_id = channel_id
    @user_id = user_id
    @message = message
    @client = client
  end

  #we still need to handle the case where they supply a time stamp/
  #do we make it interactive (list the lunches in the reply and let them pick?
  #or do we make them specify a timestamp
  def perform
    groups = base_query
    if groups.size > 1
      CommandResult.new(
        "You have more than one open group that hasn't departed yet, please provide a timestamp",
        false
      )
    elsif groups.size = 1
      group.first.destroy
      CommandResult.new(
        "Lame...",
        true
      )
    else
      CommandResult.new(
        "You don't seem to have any open lunch groups",
        false
      )
    end
  end

  private
  def base_query
    LunchGroup.where(
      initiating_user_id: user_id,
      channel_id: channel_id,
      status: 'open'
    )
  end

end


class CommandResult < Struct.new(:message, :succeeded?); end
