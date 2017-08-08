class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    channel_id = params[:channel_id]
    client = Slack::Web::Client.new
    if already_joined_channel?(client, channel_id)
      resp = client.chat_postMessage(channel: channel_id,
                              text: 'Who is in for lunch? (react with :+1:)',
                              as_user: true)

      CreateGroup
        .set(wait_until: 1.minute.from_now)
        .perform_later(channel_id, resp.message.ts)

      render plain: 'lunch? that sounds good!'
    else
      render plain: "Looks like I'm not invited :cry:"
    end
  end

  private
  def already_joined_channel?(client, channel_id)
    channel_info = client.channels_info(channel: channel_id)
    channel_info.channel.is_member
  end
end
