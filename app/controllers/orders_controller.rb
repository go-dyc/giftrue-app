class OrdersController < ApplicationController
  before_action :find_or_create_order, only: [:show, :edit, :update, :complete, :update_step]
  
  def new
    # Root page - redirect to order form if naver_order_number is provided
    if params[:naver_order_number].present?
      redirect_to order_path(params[:naver_order_number])
    else
      # Default page for testing - in production, users come from specific URLs
      render :new
    end
  end

  def show
    redirect_to edit_order_path(@order.naver_order_number)
  end

  def edit
    unless @order.can_be_edited?
      redirect_to complete_order_path(@order.naver_order_number), alert: '시안이 확정되어 더 이상 수정할 수 없습니다.'
      return
    end
    
    # 주문이 완료된 경우 complete 페이지로 자동 리디렉션 (수정 의도가 명시적이지 않은 경우에만)
    if @order.completed? && params[:force_edit] != 'true'
      redirect_to complete_order_path(@order.naver_order_number), notice: '주문이 완료되었습니다.'
      return
    end
    
    @step = (params[:step] || determine_current_step).to_i
    @step = 1 if @step < 1 || @step > 3
  end

  def create
    @order = Order.new(order_params)
    @order.naver_order_number = params[:naver_order_number] if params[:naver_order_number].present?
    
    current_step = params[:step].to_i
    
    # Debug: 파라미터 확인
    Rails.logger.info "=== CREATE DEBUG ==="
    Rails.logger.info "params[:step]: #{params[:step]}"
    Rails.logger.info "params[:next_step]: #{params[:next_step]}"
    Rails.logger.info "params[:complete_step]: #{params[:complete_step]}"
    Rails.logger.info "current_step: #{current_step}"
    Rails.logger.info "params[:next_step].present?: #{params[:next_step].present?}"
    Rails.logger.info "params[:complete_step].present?: #{params[:complete_step].present?}"
    Rails.logger.info "====================="
    
    if @order.save
      if params[:next_step].present?
        next_step = params[:next_step].to_i
        
        # 단계별 유효성 검사
        case current_step
        when 1
          @order.validating_step_1!
          if @order.valid?
            redirect_to edit_order_path(@order.naver_order_number, step: next_step)
          else
            @step = current_step
            flash.now[:alert] = '성함과 메인 사진을 모두 입력해주세요.'
            render :edit
            return
          end
        when 2
          redirect_to edit_order_path(@order.naver_order_number, step: next_step)
        when 3
          @order.validating_complete!
          if @order.valid?
            redirect_to complete_order_path(@order.naver_order_number), notice: '주문이 성공적으로 완료되었습니다.'
          else
            @step = current_step
            flash.now[:alert] = '기념패 스타일과 문구를 모두 입력해주세요.'
            render :edit
            return
          end
        end
      elsif params[:complete_step].present?
        @order.validating_complete!
        if @order.valid?
          redirect_to complete_order_path(@order.naver_order_number), notice: '주문이 성공적으로 완료되었습니다.'
        else
          @step = current_step
          flash.now[:alert] = '기념패 스타일과 문구를 모두 입력해주세요.'
          render :edit
        end
      else
        @step = current_step
        flash.now[:notice] = '주문 정보가 저장되었습니다.'
        render :edit
      end
    else
      @step = current_step
      flash.now[:alert] = '입력 정보를 확인해주세요.'
      render :edit
    end
  end

  def update
    unless @order.can_be_edited?
      redirect_to complete_order_path(@order.naver_order_number), alert: '시안이 확정되어 더 이상 수정할 수 없습니다.'
      return
    end
    
    current_step = params[:step].to_i
    
    # Debug: 파라미터 확인
    Rails.logger.info "=== UPDATE DEBUG ==="
    Rails.logger.info "params[:step]: #{params[:step]}"
    Rails.logger.info "params[:next_step]: #{params[:next_step]}"
    Rails.logger.info "params[:complete_step]: #{params[:complete_step]}"
    Rails.logger.info "current_step: #{current_step}"
    Rails.logger.info "params[:next_step].present?: #{params[:next_step].present?}"
    Rails.logger.info "params[:complete_step].present?: #{params[:complete_step].present?}"
    Rails.logger.info "====================="
    
    Rails.logger.info "=== UPDATE ATTEMPT ==="
    Rails.logger.info "order_params: #{order_params}"
    Rails.logger.info "========================"
    
    if @order.update(order_params)
      Rails.logger.info "UPDATE SUCCESS!"
      if params[:next_step].present?
        next_step = params[:next_step].to_i
        
        # 단계별 유효성 검사
        case current_step
        when 1
          @order.validating_step_1!
          if @order.valid?
            redirect_to edit_order_path(@order.naver_order_number, step: next_step)
          else
            @step = current_step
            flash.now[:alert] = '성함과 메인 사진을 모두 입력해주세요.'
            render :edit
            return
          end
        when 2
          redirect_to edit_order_path(@order.naver_order_number, step: next_step)
        when 3
          @order.validating_complete!
          if @order.valid?
            redirect_to complete_order_path(@order.naver_order_number), notice: '주문이 성공적으로 완료되었습니다.'
          else
            @step = current_step
            flash.now[:alert] = '기념패 스타일과 문구를 모두 입력해주세요.'
            render :edit
            return
          end
        end
      elsif params[:complete_step].present?
        Rails.logger.info "COMPLETE_STEP - Going to complete!"
        @order.validating_complete!
        if @order.valid?
          redirect_to complete_order_path(@order.naver_order_number), notice: '주문이 성공적으로 완료되었습니다.'
        else
          @step = current_step
          flash.now[:alert] = '기념패 스타일과 문구를 모두 입력해주세요.'
          render :edit
        end
      else
        Rails.logger.info "NO NEXT_STEP - Staying on current step"
        @step = current_step
        flash.now[:notice] = '주문 정보가 저장되었습니다.'
        render :edit
      end
    else
      Rails.logger.info "UPDATE FAILED!"
      Rails.logger.info "Errors: #{@order.errors.full_messages}"
      @step = current_step
      flash.now[:alert] = '입력 정보를 확인해주세요.'
      render :edit
    end
  end

  def update_step
    update
  end

  def complete
    unless @order.persisted?
      redirect_to edit_order_path(@order.naver_order_number)
    end
  end

  private

  def find_or_create_order
    @order = Order.find_by(naver_order_number: params[:naver_order_number])
    if @order.nil?
      @order = Order.new(naver_order_number: params[:naver_order_number], status: '주문접수')
      # Step 1에서 최소한의 정보로 DB에 저장
      if params[:action] == 'create' || params[:action] == 'update'
        @order.save(validate: false) # 검증 없이 일단 저장
      end
    end
  end

  def determine_current_step
    return 1 if @order.orderer_name.blank? || !@order.main_images.attached?
    return 2 if @order.plaque_style.blank?
    return 3 if @order.plaque_message.blank?
    3
  end

  def order_params
    # 모든 단계에서 모든 파라미터를 허용하여 데이터 유지
    permitted_params = params.require(:order).permit(:orderer_name, :plaque_style, :plaque_message, :additional_requests, 
                                                    :plaque_title, :plaque_name, :plaque_content, :plaque_top_message, :plaque_main_message,
                                                    main_images: [], optional_images: [])
    
    # 빈 이미지 배열 필터링 (기존 이미지가 있을 때 빈 값으로 덮어쓰지 않도록)
    if permitted_params[:main_images].present? && permitted_params[:main_images].all?(&:blank?)
      permitted_params.delete(:main_images)
    end
    
    if permitted_params[:optional_images].present? && permitted_params[:optional_images].all?(&:blank?)
      permitted_params.delete(:optional_images)
    end
    
    permitted_params
  end
end