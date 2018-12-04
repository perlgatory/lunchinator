class SlackUser
  attr_reader :id

  def initialize(user_id)
    @id = user_id
  end

  def username
    "<@#{id}>"
  end
end
