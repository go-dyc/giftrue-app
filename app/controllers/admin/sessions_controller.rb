class Admin::SessionsController < ApplicationController
  layout 'admin'
  
  before_action :redirect_if_logged_in, only: [:new, :create]
  
  def new
    # 로그인 페이지
  end

  def create
    # 간단한 하드코딩된 인증 (실제 환경에서는 DB 사용)
    admin_id = params[:admin_id]
    password = params[:password]
    
    if admin_id == "admin" && password == "password123"
      session[:admin_logged_in] = true
      session[:admin_id] = admin_id
      redirect_to admin_root_path, notice: '로그인되었습니다.'
    else
      flash.now[:alert] = '아이디 또는 비밀번호가 잘못되었습니다.'
      render :new
    end
  end

  def destroy
    session[:admin_logged_in] = false
    session[:admin_id] = nil
    redirect_to admin_login_path, notice: '로그아웃되었습니다.'
  end

  private

  def redirect_if_logged_in
    redirect_to admin_root_path if session[:admin_logged_in]
  end
end