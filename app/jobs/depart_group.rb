class DepartGroup < ApplicationJob
  include ApplicationHelper

  def perform(group_id)
    group = LunchGroup.find(group_id)
    group.update(status: 'departed')
    lunch_time = format_time_for_user(group.departure_time, group.initiating_user, client)
    client.chat_update(
      channel: group.channel_id, ts: group.message_id,
      text: "A group has departed for #{group.destination_string} at #{lunch_time}. Contact #{group.initiating_user.username} to join."
    )
  end
end
