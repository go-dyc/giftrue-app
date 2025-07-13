class AddPlaqueAdditionalRequestsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :plaque_additional_requests, :text
  end
end
