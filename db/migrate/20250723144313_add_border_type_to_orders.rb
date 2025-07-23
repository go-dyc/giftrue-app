class AddBorderTypeToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :border_type, :string, default: 'type_c'
    add_index :orders, :border_type
  end
end
