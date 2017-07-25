class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end
end
