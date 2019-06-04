class LunchtimePicker
  #for now this is specific to destruction--be sure to change the message if we find another use for it!
  def self.generate(lunchtimes, timezone, purpose)
    options = lunchtimes.map { |x| generate_option(x, timezone) }
    <<~SELECTOR.squish
[
    {
        "type": "section",
        "text": {
            "type": "mrkdwn",
            "text": "Select a victim:"
        },
        "accessory": {
            "action_id": "#{purpose}",
            "type": "static_select",
            "placeholder": {
                "type": "plain_text",
                "emoji": true,
                "text": "Select a time"
            },
            "options": [
              #{options.join(",")}
            ]
        }
    }
]
    SELECTOR
  end

  def self.generate_option(lunchtime, timezone)
    formatted_lunchtime = DateFormat.for_timezone(lunchtime, timezone)
    <<~OPTION.squish
                    {
                    "text": {
                        "type": "plain_text",
                        "emoji": true,
                        "text": "#{formatted_lunchtime}"
                    },
                    "value": "#{lunchtime}"
                }
    OPTION
  end
end
