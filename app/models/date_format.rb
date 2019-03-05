class DateFormat
  def self.for_timezone(time, timezone)
    time.in_time_zone(timezone).strftime(format_string)
  end

  def self.format_string
   '%H:%M:%S (%Z) %d-%b-%Y'
  end
end
