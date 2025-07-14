class SlackNotificationService
  def self.send_order_completion_notification(order)
    new.send_order_completion_notification(order)
  end
  
  def self.send_test_notification(message = "🧪 테스트 메시지")
    new.send_simple_notification(message)
  end

  def initialize
    @webhook_url = "https://hooks.slack.com/services/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"
  end

  def send_order_completion_notification(order)
    return false unless valid_setup?
    return false unless order.completed?
    
    begin
      send_http_request(build_order_message(order))
      Rails.logger.info "✅ Slack 주문 알림 전송 성공: #{order.naver_order_number}"
      true
    rescue => e
      Rails.logger.error "❌ Slack 주문 알림 전송 실패: #{e.message}"
      false
    end
  end
  
  def send_simple_notification(text)
    return false unless valid_setup?
    
    begin
      send_http_request({ text: text })
      Rails.logger.info "✅ Slack 간단 알림 전송 성공"
      true
    rescue => e
      Rails.logger.error "❌ Slack 간단 알림 전송 실패: #{e.message}"
      false
    end
  end

  private

  def valid_setup?
    @webhook_url.present?
  end

  def build_order_message(order)
    # 기념패 스타일을 한글로 변환
    plaque_style_korean = case order.plaque_style
                         when 'gold_metal' then '🥇 금속패(골드)'
                         when 'silver_metal' then '🥈 금속패(실버)'
                         when 'acrylic_cartoon' then '🎨 아크릴패(카툰)'
                         when 'acrylic_realistic' then '📸 아크릴패(실사)'
                         else order.plaque_style
                         end
    
    # 첨부 파일 개수
    main_images_count = order.main_images.attached? ? order.main_images.count : 0
    optional_images_count = order.optional_images.attached? ? order.optional_images.count : 0
    
    # 관리자 페이지 링크
    admin_url = if Rails.env.production?
                  "https://www.giftrue.com/admin/orders/#{order.id}"
                else
                  "http://localhost:3000/admin/orders/#{order.id}"
                end
    
    {
      text: "🎉 *새 주문이 접수되었습니다!*",
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "🎉 *새 주문이 접수되었습니다!*"
          }
        },
        {
          type: "section",
          fields: [
            {
              type: "mrkdwn",
              text: "*주문번호:*\n#{order.naver_order_number}"
            },
            {
              type: "mrkdwn", 
              text: "*고객명:*\n#{order.orderer_name}"
            },
            {
              type: "mrkdwn",
              text: "*기념패 스타일:*\n#{plaque_style_korean}"
            },
            {
              type: "mrkdwn",
              text: "*첨부 파일:*\n정면사진 #{main_images_count}개, 포즈사진 #{optional_images_count}개"
            }
          ]
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*예상 배송일:* #{order.expected_delivery_date.strftime('%Y년 %m월 %d일')}"
          }
        },
        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: {
                type: "plain_text",
                text: "📋 주문 상세보기"
              },
              url: admin_url
            }
          ]
        }
      ]
    }
  end

  def send_http_request(message)
    require 'net/http'
    require 'json'
    
    uri = URI(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    response = http.post(uri.path, message.to_json, { 'Content-Type' => 'application/json' })
    
    unless response.code == '200' && response.body == 'ok'
      raise "Slack API 오류: #{response.code} - #{response.body}"
    end
    
    response
  end
end