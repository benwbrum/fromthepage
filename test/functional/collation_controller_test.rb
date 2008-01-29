require File.dirname(__FILE__) + '/../test_helper'
require 'collation_controller'

# Re-raise errors caught by the controller.
class CollationController; def rescue_action(e) raise e end; end

class CollationControllerTest < Test::Unit::TestCase
  def setup
    @controller = CollationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
