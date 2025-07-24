class AddReferenceImageIndexToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :reference_image_index, :integer
  end
end
