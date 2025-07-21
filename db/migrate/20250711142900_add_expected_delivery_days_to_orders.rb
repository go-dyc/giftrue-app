class AddExpectedDeliveryDaysToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :expected_delivery_days, :integer, default: 15
  end
end
