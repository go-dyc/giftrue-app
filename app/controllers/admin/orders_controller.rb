class Admin::OrdersController < ApplicationController
  layout 'admin'
  before_action :require_admin_login
  before_action :set_order, only: [:show, :update, :update_status, :update_delivery_days]

  def index
    @status_filter = params[:status] || '주문접수'
    @orders = if @status_filter == '전체'
                Order.all.recent.includes(main_images_attachments: :blob)
              else
                Order.by_status(@status_filter).recent.includes(main_images_attachments: :blob)
              end
    
    @status_counts = {
      '전체' => Order.count,
      '주문접수' => Order.by_status('주문접수').count,
      '시안확정' => Order.by_status('시안확정').count,
      '제작중' => Order.by_status('제작중').count,
      '배송중' => Order.by_status('배송중').count,
      '배송완료' => Order.by_status('배송완료').count
    }
  end

  def show
    # 주문 상세 정보 표시
  end

  def update
    redirect_to admin_order_path(@order)
  end

  def update_status
    if @order.update(status: params[:status])
      redirect_to admin_order_path(@order), notice: '주문 상태가 변경되었습니다.'
    else
      redirect_to admin_order_path(@order), alert: '상태 변경에 실패했습니다.'
    end
  end

  def update_delivery_days
    if @order.update(expected_delivery_days: params[:expected_delivery_days])
      redirect_to admin_order_path(@order), notice: '예상 수령일이 변경되었습니다.'
    else
      redirect_to admin_order_path(@order), alert: '예상 수령일 변경에 실패했습니다.'
    end
  end

  private

  def set_order
    @order = Order.find_by!(naver_order_number: params[:id])
  end

  def order_params
    params.require(:order).permit(:status)
  end
end
