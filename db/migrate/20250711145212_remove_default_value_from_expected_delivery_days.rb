class RemoveDefaultValueFromExpectedDeliveryDays < ActiveRecord::Migration[8.0]
  def change
    change_column_default :orders, :expected_delivery_days, from: 15, to: nil
  end
end
