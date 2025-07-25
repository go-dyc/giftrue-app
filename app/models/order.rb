class Order < ApplicationRecord
  # Active Storage attachments
  has_many_attached :main_images
  has_many_attached :optional_images
  
  # Validations
  validates :naver_order_number, presence: { message: "주문번호가 필요합니다" }, uniqueness: { message: "이미 존재하는 주문번호입니다" }
  validates :status, presence: true, inclusion: { in: %w[주문접수 시안확정 제작중 배송중 배송완료 주문취소] }
  validates :plaque_style, inclusion: { in: %w[gold_metal silver_metal acrylic_cartoon acrylic_realistic], allow_blank: true, message: "올바른 기념패 스타일을 선택해주세요" }
  validates :border_type, inclusion: { in: %w[type_a type_b type_c], allow_blank: true, message: "올바른 테두리 타입을 선택해주세요" }
  validates :expected_delivery_days, presence: { message: "배송일이 필요합니다" }, numericality: { greater_than: 0, less_than_or_equal_to: 90, greater_than_message: "배송일은 1일 이상이어야 합니다", less_than_or_equal_to_message: "배송일은 90일 이하여야 합니다" }
  
  # 새 주문 생성 시 및 업데이트 시 시스템 기본값 적용
  before_validation :set_default_delivery_days
  
  # 주문 완료 시 슬랙 알림 발송
  after_update :send_slack_notification_if_completed
  
  # Step-based validations
  validates :orderer_name, presence: { message: "주문자 성함을 입력해주세요" }, if: :validate_step_1_or_complete?
  validates :main_images, presence: { message: "정면 사진을 업로드해주세요" }, if: :validate_step_1_or_complete?
  validates :optional_images, presence: { message: "포즈 및 의상 사진을 업로드해주세요" }, if: :validate_step_2_or_complete?
  validates :plaque_style, presence: { message: "기념패 스타일을 선택해주세요" }, if: :validate_step_3_or_complete?
  # Remove old plaque_message validation - replaced with detailed field validations
  # validates :plaque_message, presence: true, if: :validate_step_3_or_complete?
  
  # New detailed field validations - individual fields are not required, but at least one must be filled
  # validates :plaque_title, presence: true, if: :validate_metal_plaque_fields?
  # validates :plaque_name, presence: true, if: :validate_metal_plaque_fields?
  # validates :plaque_content, presence: true, if: :validate_metal_plaque_fields?
  # validates :plaque_top_message, presence: true, if: :validate_acrylic_plaque_fields?
  # validates :plaque_main_message, presence: true, if: :validate_acrylic_plaque_fields?
  
  # Custom validation to ensure at least one set of fields is filled
  validate :validate_plaque_fields_completion, if: :validate_step_3_or_complete?
  
  # Length validations for new fields (with Korean messages)
  validates :plaque_title, length: { maximum: 15, too_long: "제목은 15자를 초과할 수 없습니다" }, if: :validate_metal_plaque_fields?
  validates :plaque_name, length: { maximum: 40, too_long: "성함은 40자를 초과할 수 없습니다" }, if: :validate_metal_plaque_fields?
  validates :plaque_content, length: { maximum: 150, too_long: "본문은 150자를 초과할 수 없습니다" }, if: :validate_metal_plaque_fields?
  validates :plaque_top_message, length: { maximum: 10, too_long: "상단문구는 10자를 초과할 수 없습니다" }, if: :validate_acrylic_plaque_fields?
  validates :plaque_main_message, length: { maximum: 25, too_long: "메시지는 25자를 초과할 수 없습니다" }, if: :validate_acrylic_plaque_fields?
  
  # Reference image validation for acrylic plaques (with Korean messages)
  validates :reference_image_index, presence: { message: "아크릴패 참조 사진을 선택해주세요" }, if: :validate_acrylic_plaque_fields?
  validates :reference_image_index, inclusion: { in: 0..4, message: "올바른 참조 사진을 선택해주세요" }, if: :validate_acrylic_plaque_fields?
  
  # Custom validation for file types and sizes
  validate :validate_main_images_content_type_and_size
  validate :validate_optional_images_content_type_and_size
  validate :validate_main_images_count
  validate :validate_optional_images_count
  
  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :cancelled, -> { where.not(cancelled_at: nil) }
  scope :active, -> { where(cancelled_at: nil) }
  scope :needs_polling, -> { active.where(last_api_polled_at: [nil, ...5.minutes.ago]) }
  
  # Instance methods
  def can_be_edited?
    status == '주문접수' && !cancelled?
  end
  
  def cancelled?
    cancelled_at.present?
  end
  
  def cancel!(reason = nil)
    update!(
      cancelled_at: Time.current,
      status: '주문취소',
      cancellation_reason: reason
    )
  end
  
  def completed?
    # 취소된 주문은 완료되지 않은 것으로 간주
    return false if cancelled?
    
    # 주문이 완료된 것으로 간주하는 조건: 모든 필수 정보가 입력되었고 저장되어 있는 경우
    return false if naver_order_number.blank? || orderer_name.blank? || plaque_style.blank?
    return false unless main_images.attached?
    return false unless optional_images.attached?
    
    # 스타일별 세부 필드 확인
    case plaque_style
    when 'gold_metal', 'silver_metal'
      !(plaque_title.blank? && plaque_name.blank? && plaque_content.blank?)
    when 'acrylic_cartoon', 'acrylic_realistic'
      !(plaque_top_message.blank? && plaque_main_message.blank?) && reference_image_index.present?
    else
      false
    end
  end
  
  def expected_delivery_date
    created_at + (expected_delivery_days || SystemSetting.default_delivery_days).days
  end
  
  def to_param
    naver_order_number
  end
  
  # Validation context methods
  def validate_step_1_or_complete?
    # Step 1 검증이 필요한 경우 또는 완전한 주문인 경우
    @validating_step_1 || @validating_complete || (orderer_name.present? || main_images.attached?)
  end
  
  def validate_step_2_or_complete?
    # Step 2 검증이 필요한 경우 또는 완전한 주문인 경우
    @validating_step_2 || @validating_complete || optional_images.attached?
  end
  
  def validate_step_3_or_complete?
    # Step 3 검증이 필요한 경우 또는 완전한 주문인 경우
    @validating_step_3 || @validating_complete || plaque_style.present?
  end
  
  # Validation context setters
  def validating_step_1!
    @validating_step_1 = true
  end
  
  def validating_step_2!
    @validating_step_2 = true
  end
  
  def validating_step_3!
    @validating_step_3 = true
  end
  
  def validating_complete!
    @validating_complete = true
  end
  
  # Additional validation context methods
  def validate_metal_plaque_fields?
    (@validating_step_3 || @validating_complete) && ['gold_metal', 'silver_metal'].include?(plaque_style)
  end
  
  def validate_acrylic_plaque_fields?
    (@validating_step_3 || @validating_complete) && ['acrylic_cartoon', 'acrylic_realistic'].include?(plaque_style)
  end

  # Custom validation method to ensure proper field completion
  def validate_plaque_fields_completion
    return unless plaque_style.present?
    
    case plaque_style
    when 'gold_metal', 'silver_metal'
      # For metal plaques, check if at least one field has content
      if plaque_title.blank? && plaque_name.blank? && plaque_content.blank?
        errors.add(:base, '제목, 성함, 본문 중 최소 하나는 입력해주세요.')
      end
    when 'acrylic_cartoon', 'acrylic_realistic'
      # For acrylic plaques, check if at least one field has content
      if plaque_top_message.blank? && plaque_main_message.blank?
        errors.add(:base, '상단문구, 메시지 중 최소 하나는 입력해주세요.')
      end
    end
  end

  private

  def validate_main_images_content_type_and_size
    return unless main_images.attached?

    main_images.each do |image|
      unless image.content_type.in?(['image/jpeg', 'image/png'])
        errors.add(:main_images, 'JPG 또는 PNG 파일만 업로드할 수 있습니다.')
      end

      if image.byte_size > 10.megabytes
        errors.add(:main_images, '파일 크기는 10MB를 초과할 수 없습니다.')
      end
    end
  end

  def validate_optional_images_content_type_and_size
    return unless optional_images.attached?

    optional_images.each do |image|
      unless image.content_type.in?(['image/jpeg', 'image/png'])
        errors.add(:optional_images, 'JPG 또는 PNG 파일만 업로드할 수 있습니다.')
      end

      if image.byte_size > 10.megabytes
        errors.add(:optional_images, '파일 크기는 10MB를 초과할 수 없습니다.')
      end
    end
  end

  def validate_main_images_count
    return unless main_images.attached?

    if main_images.count > 5
      errors.add(:main_images, '메인 사진은 최대 5개까지 업로드할 수 있습니다.')
    end
  end

  def validate_optional_images_count
    return unless optional_images.attached?

    if optional_images.count > 5
      errors.add(:optional_images, '포즈 및 의상 사진은 최대 5개까지 업로드할 수 있습니다.')
    end
  end
  
  # 새 주문 생성 시 시스템 기본값 설정
  def set_default_delivery_days
    self.expected_delivery_days ||= SystemSetting.default_delivery_days
  end
  
  # 주문이 완료되었을 때 슬랙 알림 발송
  def send_slack_notification_if_completed
    # 주문이 새로 완료된 경우에만 알림 발송 (중복 방지)
    if completed? && !@slack_notification_sent
      SlackNotificationJob.perform_later(self)
      @slack_notification_sent = true
    end
  end
end
