class SlackUser
  attr_reader :id

  def initialize(user_id)
    @id = user_id
  end

  def username
    "<@#{id}>"
  end

  def timezone(client)
    # https://api.slack.com/methods/users.info <- get user timezone from here
    user_response = client.users_info(user: id)
    # check that response is good
    status_ok = user_response.ok
    unless status_ok
      return :not_ok # TODO: Handle this
    end
    user_response.user.tz
  end
end
