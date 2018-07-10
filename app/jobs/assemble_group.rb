class AssembleGroup < ApplicationJob
  def perform(channel_id, initiating_user_id, message_id)
    users_to_notify = get_users_who_reacted(channel_id, message_id)
    group_id = create_group(initiating_user_id, users_to_notify)
    group = LunchGroup.select(channel_id: channel_id, message_id: message_id).first
    destination = group.destination
    notify_users(group_id, destination)
    create_poll(group_id) if destination.nil?
    group.update(status: 'assembled')
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

  def notify_users(group_id, destination)
    destination ||= "lunch"
    client.chat_postMessage(channel: group_id,
                            text: "Hey, you're stuck having #{destination} together",
                            as_user: true)
  end

  def create_poll(group_id)
    nums = ["one","two","three","four","five","six","seven","eight","nine","ten"]
    places_rand = Place.order("RANDOM()").limit(10).map(&:name)
    text = "Where do you want to go?\n"
    nums.zip(places_rand).each do |num, place|
        text += ":#{num}: #{place}\n"
    end
    resp = client.chat_postMessage(channel: group_id,
                            text: text,
                            as_user: true)
    response_ts = resp.message.ts
    nums.each do |num|
        client.reactions_add(name: num, channel: group_id, timestamp: response_ts)
    end    
  end
end
