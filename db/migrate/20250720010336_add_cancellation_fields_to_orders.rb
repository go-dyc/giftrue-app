class AddCancellationFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :cancelled_at, :datetime
    add_column :orders, :cancellation_reason, :text
    add_column :orders, :last_api_polled_at, :datetime
    
    add_index :orders, :cancelled_at
    add_index :orders, :last_api_polled_at
  end
end
