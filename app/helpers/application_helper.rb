module ApplicationHelper
  def format_time_for_user(time, user, client)
    user_time_zone = user.timezone(client)
    time.in_time_zone(user_time_zone).strftime('%H:%M:%S (%Z) %d-%b-%Y')
  end
end
