class ApplicationController < ActionController::Base
  def test
    render plain: 'hello, world'
  end

  def lunch
    render plain: 'lunch? that sounds good!'
  end
end
