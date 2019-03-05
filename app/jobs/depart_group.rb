class DepartGroup < ApplicationJob

  def perform(group_id)
    group = LunchGroup.find(group_id)
    group.update(status: 'departed')

    lunch_time = DateFormat.for_timezone(
      group.departure_time,
      group.initiating_user.timezone(client)
    )

    client.chat_update(
      channel: group.channel_id, ts: group.message_id,
      text: "A group has departed for #{group.destination_string} at #{lunch_time}. Contact #{group.initiating_user.username} to join."
    )
  end
end
