class DepartGroup < ApplicationJob
  def perform(group_id)
    group = LunchGroup.find(group_id)
    group.update(status: 'departed')
  end
end
