require File.dirname(__FILE__) + '/../test_helper'
require 'image_set_controller'

# Re-raise errors caught by the controller.
class ImageSetController; def rescue_action(e) raise e end; end

class ImageSetControllerTest < Test::Unit::TestCase
  def setup
    @controller = ImageSetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
