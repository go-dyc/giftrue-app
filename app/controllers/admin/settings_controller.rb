class Admin::SettingsController < ApplicationController
  layout 'admin'
  before_action :require_admin_login

  def index
    @default_delivery_days = SystemSetting.default_delivery_days
  end

  def update
    if params[:default_delivery_days].present?
      days = params[:default_delivery_days].to_i
      
      if days >= 1 && days <= 90
        SystemSetting.set_default_delivery_days(days)
        redirect_to admin_settings_path, notice: "기본 제작 기간이 #{days}일로 변경되었습니다."
      else
        redirect_to admin_settings_path, alert: "제작 기간은 1일~90일 사이로 설정해주세요."
      end
    else
      redirect_to admin_settings_path, alert: "유효한 값을 입력해주세요."
    end
  end
end
