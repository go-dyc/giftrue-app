class AddCustomFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :relationship_giver, :string
    add_column :orders, :relationship_receiver, :string
    add_column :orders, :purpose_custom, :string
    add_column :orders, :tone_custom, :string
  end
end
