class AddBorderFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :border_type, :string, default: 'type_c'
    add_column :orders, :border_scale, :decimal, precision: 3, scale: 2, default: 1.0
    add_column :orders, :font_style, :string, default: 'elegant'
    
    # 인덱스 추가 (검색 성능 향상)
    add_index :orders, :border_type
    add_index :orders, :font_style
  end
end
