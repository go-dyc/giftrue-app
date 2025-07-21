class Admin::ApiTestController < ApplicationController
  layout 'admin'
  before_action :require_admin_login
  
  def index
    # API 테스트 메인 페이지
  end
  
  def test_connection
    # .env 파일 직접 로드 시도
    begin
      env_file = Rails.root.join('.env')
      if File.exist?(env_file)
        File.read(env_file).each_line do |line|
          line.strip!
          next if line.empty? || line.start_with?('#')
          key, value = line.split('=', 2)
          ENV[key] = value if key && value
        end
      end
    rescue => e
      Rails.logger.error "Failed to load .env: #{e.message}"
    end
    
    begin
      api_service = NaverApiService.new
      
      # 환경변수 확인
      result = {
        status: 'success',
        message: 'NaverApiService 초기화 성공',
        client_id: ENV['NAVER_COMMERCE_API_CLIENT_ID']&.first(10) + '...',
        has_secret: ENV['NAVER_COMMERCE_API_CLIENT_SECRET'].present?,
        debug_info: {
          env_file_exists: File.exist?(Rails.root.join('.env')),
          client_id_length: ENV['NAVER_COMMERCE_API_CLIENT_ID']&.length,
          secret_length: ENV['NAVER_COMMERCE_API_CLIENT_SECRET']&.length
        }
      }
    rescue => e
      result = {
        status: 'error',
        message: e.message,
        client_id: ENV['NAVER_COMMERCE_API_CLIENT_ID'],
        has_secret: ENV['NAVER_COMMERCE_API_CLIENT_SECRET'].present?,
        debug_info: {
          env_file_exists: File.exist?(Rails.root.join('.env')),
          client_id_length: ENV['NAVER_COMMERCE_API_CLIENT_ID']&.length,
          secret_length: ENV['NAVER_COMMERCE_API_CLIENT_SECRET']&.length
        }
      }
    end
    
    render json: result
  end
  
  def test_token
    begin
      api_service = NaverApiService.new
      token = api_service.send(:fetch_access_token)
      
      render json: {
        status: 'success',
        message: 'Access token 발급 성공',
        token_preview: token&.first(20) + '...'
      }
    rescue => e
      render json: {
        status: 'error',
        message: e.message
      }
    end
  end
  
  def test_order_check
    order_number = params[:order_number] || 'test1'
    
    begin
      api_service = NaverApiService.new
      result = api_service.check_order_status(order_number)
      
      render json: {
        status: 'success',
        order_number: order_number,
        result: result
      }
    rescue => e
      render json: {
        status: 'error',
        message: e.message,
        order_number: order_number
      }
    end
  end
end