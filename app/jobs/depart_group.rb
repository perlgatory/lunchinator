class DepartGroup < ApplicationJob
  def perform(group_id)
    group = LunchGroup.find(group_id)
    group.update(status: 'departed')
    user_time_zone = group.initiating_user.timezone(client)
    lunch_time = group.departure_time.in_time_zone(user_time_zone)
    client.chat_update(
      channel: group.channel_id, ts: group.message_id,
      text: "A group has departed for #{group.destination_string} at #{lunch_time}. Contact #{group.initiating_user.username} to join."
    )
  end
end
