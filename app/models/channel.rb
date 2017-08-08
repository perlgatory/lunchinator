class Channel
  attr_reader :channel_id

  def initialize(channel_id)
    @channel_id = channel_id
  end

  def client_status(client)
    channel_info = client.channels_info(channel: channel_id)
    if channel_info.channel.is_member
      :already_joined
    else
      :not_joined
    end
  rescue Slack::Web::Api::Error => e
    if e.message =~ /channel_not_found/
      return :cannot_see
    end
  end
end
