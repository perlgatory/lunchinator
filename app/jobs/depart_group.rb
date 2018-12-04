class DepartGroup < ApplicationJob
  def perform(group_id)
    group = LunchGroup.find(group_id)
    group.update(status: 'departed')
    client.chat_update(
      channel: group.channel_id, ts: group.message_id,
      text: "A group has departed for #{group.destination_string} at #{group.departure_time}. Contact #{group.initiating_user.username} to join."
    )
  end
end
