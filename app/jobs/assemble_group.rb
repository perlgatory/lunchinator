class AssembleGroup < ApplicationJob
  def perform(channel_id, initiating_user_id, message_id)
    users_to_notify = get_users_who_reacted(channel_id, message_id)
    group_id = create_group(initiating_user_id, users_to_notify)
    notify_users(group_id)
  end

  private
  def client
    @client ||= Slack::Web::Client.new
  end

  def get_users_who_reacted(channel_id, message_id)
    reactions_response = client.reactions_get(
      channel: channel_id,
      timestamp: message_id
    )

    if reactions_response.ok
      reactions_response.message
        .reactions
        .select { |r| r.name == '+1' }
        .flat_map { |r| r.users }
        .uniq
    else
      []
    end
  end

  def create_group(initiating_user_id, users)
    all_users = (users << initiating_user_id)
      .uniq
      .join(',')
    resp = client.mpim_open(users: all_users)
    if resp.ok
      resp.group.id
    else
      nil
    end
  end

  def notify_users(group_id)
    client.chat_postMessage(channel: group_id,
                            text: "Hey, you're stuck going to lunch together",
                            as_user: true)
  end
end