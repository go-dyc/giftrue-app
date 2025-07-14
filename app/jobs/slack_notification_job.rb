class SlackNotificationJob < ApplicationJob
  queue_as :default

  def perform(order)
    return unless order.completed?
    
    success = SlackNotificationService.send_order_completion_notification(order)
    
    unless success
      raise "Slack 알림 전송 실패: 주문번호 #{order.naver_order_number}"
    end
  end
end