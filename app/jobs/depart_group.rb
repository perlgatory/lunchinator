class DepartGroup < ApplicationJob
  def perform(group_id)
    group = LunchGroup.find(group_id)
    group.update(status: 'departed')
    client.chat_delete(channel: group.channel_id, ts: group.message_id)
  end
end
