class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    channel_id = params[:channel_id]
    client = Slack::Web::Client.new
    status = channel_status(client, channel_id)
    if status == :already_joined
      resp = client.chat_postMessage(channel: channel_id,
                              text: 'Who is in for lunch? (react with :+1:)',
                              as_user: true)
      CreateGroup
        .set(wait_until: 1.minute.from_now)
        .perform_later(channel_id, resp.message.ts)
      render plain: 'lunch? that sounds good!'
    elsif status == :not_joined
      render plain: "Looks like I'm not invited :cry:"
    else
      render plain: "I'm not allowed in there :slightly_frowning_face:"
    end
  end

  private
  def channel_status(client, channel_id)
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
