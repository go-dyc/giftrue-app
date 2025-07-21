require 'net/http'
require 'timeout'
require 'digest'
require 'base64'
require 'json'
require 'bcrypt'

class NaverApiService
  include HTTParty
  
  BASE_URI = 'https://api.commerce.naver.com'.freeze
  
  def initialize
    @client_id = ENV['NAVER_COMMERCE_API_CLIENT_ID']
    @client_secret = ENV['NAVER_COMMERCE_API_CLIENT_SECRET']
    
    raise 'Missing Naver API credentials' if @client_id.blank? || @client_secret.blank?
  end
  
  # 주문 상태 조회
  def check_order_status(naver_order_number)
    Rails.logger.info "Checking order status for: #{naver_order_number}"
    
    begin
      response = get_order_details(naver_order_number)
      parse_order_response(response)
    rescue => e
      Rails.logger.error "API Error for order #{naver_order_number}: #{e.message}"
      handle_api_error(e)
    end
  end
  
  # 여러 주문 상태 일괄 조회
  def check_multiple_orders(order_numbers)
    results = {}
    
    order_numbers.each do |order_number|
      results[order_number] = check_order_status(order_number)
      sleep(0.5) # Rate limit 고려
    end
    
    results
  end
  
  private
  
  def get_order_details(order_number)
    url = "#{BASE_URI}/external/v1/pay-order/seller/product-orders/query"
    
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    
    body = {
      productOrderIds: [order_number]
    }.to_json
    
    self.class.post(url, headers: headers, body: body, timeout: 30)
  end
  
  def access_token
    @access_token ||= fetch_access_token
  end
  
  def fetch_access_token
    url = "#{BASE_URI}/external/v1/oauth2/token"
    
    # 네이버 API 스펙에 따른 타임스탬프 생성 (밀리초 단위)
    timestamp = (Time.now.to_f * 1000).to_i.to_s
    
    # 네이버 커머스 API 공식 스펙에 따른 올바른 시그니처 생성
    # 1. Password 생성: client_id + "_" + timestamp  
    password = "#{@client_id}_#{timestamp}"
    
    # 2. bcrypt 해싱: client_secret을 salt로 사용
    hashed = BCrypt::Engine.hash_secret(password, @client_secret)
    
    # 3. Base64 인코딩
    signature = Base64.strict_encode64(hashed)
    
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    
    body = {
      grant_type: 'client_credentials',
      client_id: @client_id,
      timestamp: timestamp,
      client_secret_sign: signature,
      type: 'SELF'
    }
    
    Rails.logger.info "Token request: timestamp=#{timestamp}, signature=#{signature[0..20]}..."
    
    response = self.class.post(url, headers: headers, body: body, timeout: 30)
    
    if response.success?
      token_data = JSON.parse(response.body)
      Rails.logger.info "Token fetch successful"
      token_data['access_token']
    else
      Rails.logger.error "Token fetch failed: #{response.code} - #{response.body}"
      raise "Token fetch failed: #{response.code} - #{response.body}"
    end
  end
  
  def parse_order_response(response)
    if response.success?
      data = JSON.parse(response.body)
      
      # 네이버 API 응답 구조에 따라 파싱
      if data['data'] && data['data']['productOrders']&.any?
        order_data = data['data']['productOrders'].first
        
        {
          status: 'success',
          order_status: map_naver_status(order_data['productOrderStatus']),
          cancelled: order_data['productOrderStatus'] == 'CANCELED',
          cancellation_reason: order_data['cancelReason'],
          last_updated: order_data['lastChangedDate'],
          raw_data: order_data
        }
      else
        {
          status: 'not_found',
          message: 'Order not found'
        }
      end
    else
      {
        status: 'error',
        code: response.code,
        message: response.body
      }
    end
  end
  
  def map_naver_status(naver_status)
    case naver_status
    when 'PAYED' then '주문접수'
    when 'DISPATCHED' then '배송중'
    when 'DELIVERED' then '배송완료'
    when 'CANCELED' then '주문취소'
    when 'EXCHANGE_REQUEST' then '교환요청'
    when 'RETURN_REQUEST' then '반품요청'
    else naver_status
    end
  end
  
  def handle_api_error(error)
    case error
    when Timeout::Error
      { status: 'timeout', message: 'API timeout' }
    when JSON::ParserError
      { status: 'parse_error', message: 'Invalid response format' }
    when HTTParty::Error
      { status: 'http_error', message: error.message }
    else
      { status: 'unknown_error', message: error.message }
    end
  end
end