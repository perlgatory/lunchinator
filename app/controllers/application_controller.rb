class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    channel_id = params[:channel_id]
    initiating_user_id = params[:user_id]
    client = Slack::Web::Client.new
    channel = Channel.new(channel_id)
    status = channel.client_status(client)
    if status == :already_joined
      resp = client.chat_postMessage(channel: channel_id,
                              text: 'Who is in for lunch? (react with :+1:)',
                              as_user: true)
      client.reactions_add(name: '+1', timestamp: resp.message.ts)
      CreateGroup
        .set(wait_until: 1.minute.from_now)
        .perform_later(channel_id, initiating_user_id, resp.message.ts)
      render plain: 'lunch? that sounds good!'
    elsif status == :not_joined
      render plain: "Looks like I'm not invited :cry:. Please invite me to the channel!"
    else
      render plain: "I'm not allowed in there :slightly_frowning_face:"
    end
  end
end
