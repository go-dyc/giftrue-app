class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :naver_order_number, null: false
      t.string :orderer_name, null: false
      t.string :plaque_style
      t.text :plaque_message
      t.text :additional_requests
      t.string :status, null: false, default: '주문접수'

      t.timestamps
    end
    add_index :orders, :naver_order_number, unique: true
  end
end
