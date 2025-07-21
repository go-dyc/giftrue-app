class Admin::SessionsController < ApplicationController
  layout 'admin'
  
  before_action :redirect_if_logged_in, only: [:new, :create]
  
  def new
    # 로그인 페이지
  end

  def create
    # 환경변수를 사용한 관리자 인증
    admin_id = params[:admin_id]
    password = params[:password]
    
    if admin_id == ENV['ADMIN_USERNAME'] && password == ENV['ADMIN_PASSWORD']
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