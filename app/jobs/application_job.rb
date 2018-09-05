class ApplicationJob < ActiveJob::Base
  private
  def client
    @client ||= Slack::Web::Client.new
  end
end
