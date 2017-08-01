class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    channel_id = params[:channel_id]
    client = Slack::Web::Client.new
    resp = client.chat_postMessage(channel: channel_id,
                            text: 'Who is in for lunch? (react with :+1:)',
                            as_user: true)

    CreateGroup
      .set(wait_until: 1.minute.from_now)
      .perform_later(channel_id, resp.message.ts)

    render plain: 'lunch? that sounds good!'
  end
end
