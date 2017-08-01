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

    CreateGroup.perform_later(channel_id,
                              resp.message.ts,
                              wait_until: 1.minute.from.now)



    render plain: 'lunch? that sounds good!'
  end
end
