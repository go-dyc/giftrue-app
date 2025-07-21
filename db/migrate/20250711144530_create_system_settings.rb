class CreateSystemSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :system_settings do |t|
      t.string :key, null: false
      t.text :value
      t.text :description

      t.timestamps
    end
    
    add_index :system_settings, :key, unique: true
    
    # 기본 제작 기간 설정 추가
    SystemSetting.create!(
      key: 'default_delivery_days',
      value: '15',
      description: '신규 주문의 기본 제작 기간 (일)'
    )
  end
end
