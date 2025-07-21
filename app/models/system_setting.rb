class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  
  # 편리한 클래스 메서드들
  def self.get(key)
    find_by(key: key)&.value
  end
  
  def self.set(key, value, description = nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.description = description if description
    setting.save!
    setting
  end
  
  def self.default_delivery_days
    get('default_delivery_days')&.to_i || 15
  end
  
  def self.set_default_delivery_days(days)
    set('default_delivery_days', days, '신규 주문의 기본 제작 기간 (일)')
  end
end
