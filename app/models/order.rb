class Order < ApplicationRecord
  # Active Storage attachments
  has_many_attached :main_images
  has_many_attached :optional_images
  
  # Validations
  validates :naver_order_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[주문접수 시안확정 제작중 배송중 배송완료] }
  validates :plaque_style, inclusion: { in: %w[gold_metal silver_metal acrylic_cartoon acrylic_realistic], allow_blank: true }
  
  # Step-based validations
  validates :orderer_name, presence: true, if: :validate_step_1_or_complete?
  validates :main_images, presence: true, if: :validate_step_1_or_complete?
  validates :plaque_style, presence: true, if: :validate_step_3_or_complete?
  validates :plaque_message, presence: true, if: :validate_step_3_or_complete?
  
  # New detailed field validations
  validates :plaque_title, presence: true, if: :validate_metal_plaque_fields?
  validates :plaque_name, presence: true, if: :validate_metal_plaque_fields?
  validates :plaque_content, presence: true, if: :validate_metal_plaque_fields?
  validates :plaque_top_message, presence: true, if: :validate_acrylic_plaque_fields?
  validates :plaque_main_message, presence: true, if: :validate_acrylic_plaque_fields?
  
  # Length validations for new fields
  validates :plaque_title, length: { maximum: 15 }, if: :validate_metal_plaque_fields?
  validates :plaque_name, length: { maximum: 40 }, if: :validate_metal_plaque_fields?
  validates :plaque_content, length: { maximum: 150 }, if: :validate_metal_plaque_fields?
  validates :plaque_top_message, length: { maximum: 10 }, if: :validate_acrylic_plaque_fields?
  validates :plaque_main_message, length: { maximum: 25 }, if: :validate_acrylic_plaque_fields?
  
  # Custom validation for file types and sizes
  validate :validate_main_images_content_type_and_size
  validate :validate_optional_images_content_type_and_size
  validate :validate_main_images_count
  
  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Instance methods
  def can_be_edited?
    status == '주문접수'
  end
  
  def expected_delivery_date
    created_at + 15.days
  end
  
  def to_param
    naver_order_number
  end
  
  # Validation context methods
  def validate_step_1_or_complete?
    # Step 1 검증이 필요한 경우 또는 완전한 주문인 경우
    @validating_step_1 || @validating_complete || (orderer_name.present? || main_images.attached?)
  end
  
  def validate_step_3_or_complete?
    # Step 3 검증이 필요한 경우 또는 완전한 주문인 경우
    @validating_step_3 || @validating_complete || plaque_style.present?
  end
  
  # Validation context setters
  def validating_step_1!
    @validating_step_1 = true
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
end
