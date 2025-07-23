class RemovePreviewFieldsFromOrders < ActiveRecord::Migration[8.0]
  def change
    # 인덱스 먼저 제거
    remove_index :orders, :border_type if index_exists?(:orders, :border_type)
    remove_index :orders, :font_style if index_exists?(:orders, :font_style)
    
    # 컬럼 제거
    remove_column :orders, :border_type, :string, default: 'type_c'
    remove_column :orders, :border_scale, :decimal, precision: 3, scale: 2, default: 1.0
    remove_column :orders, :font_style, :string, default: 'elegant'
  end
end
