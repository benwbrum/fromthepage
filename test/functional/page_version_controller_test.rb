require File.dirname(__FILE__) + '/../test_helper'
require 'page_version_controller'

# Re-raise errors caught by the controller.
class PageVersionController; def rescue_action(e) raise e end; end

class PageVersionControllerTest < Test::Unit::TestCase
  def setup
    @controller = PageVersionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
