class AddAiContextFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :relationship, :string
    add_column :orders, :purpose, :string
    add_column :orders, :tone, :string
    add_column :orders, :special_note, :text
  end
end
