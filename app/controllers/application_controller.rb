class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def require_admin_login
    unless session[:admin_logged_in]
      redirect_to admin_login_path, alert: '관리자 로그인이 필요합니다.'
    end
  end

  def current_admin
    session[:admin_id] if session[:admin_logged_in]
  end

  helper_method :current_admin
end
