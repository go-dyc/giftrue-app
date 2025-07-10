require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get orders_new_url
    assert_response :success
  end

  test "should get show" do
    get orders_show_url
    assert_response :success
  end

  test "should get edit" do
    get orders_edit_url
    assert_response :success
  end

  test "should get complete" do
    get orders_complete_url
    assert_response :success
  end

  test "should get update_step" do
    get orders_update_step_url
    assert_response :success
  end
end
