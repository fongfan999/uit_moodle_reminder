require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "should get thankyou" do
    get home_thankyou_url
    assert_response :success
  end

end
