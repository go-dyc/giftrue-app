class AddDetailedPlaqueFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :plaque_title, :string
    add_column :orders, :plaque_name, :string
    add_column :orders, :plaque_content, :text
    add_column :orders, :plaque_top_message, :string
    add_column :orders, :plaque_main_message, :string
  end
end
