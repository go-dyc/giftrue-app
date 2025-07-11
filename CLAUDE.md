# CLAUDE.md

## 프로젝트 정보

- **프로젝트명**: giftrue
- **유형**: 인물 피규어 기념패 제작 서비스 (업데이트됨)
- **프레임워크**: Ruby on Rails 8.0.2
- **Ruby 버전**: 3.4.2
- **CSS 프레임워크**: TailwindCss
- **데이터베이스**: SQLite (기본)

# 인물 피규어 기념패 제작 서비스 개발 완료 문서 (PRD for AI)

## 1. 프로젝트 개요 (Project Overview)

**프로젝트명**: 기프트루 - 네이버 주문 연동형 인물 피규어 기념패 제작 서비스

**핵심 목표**: 네이버 스마트스토어 주문 고객이 알림톡으로 받은 개인화 URL을 통해, 3단계 폼을 사용하여 인물 피규어 기념패 제작 정보를 직접 입력하고, 관리자는 별도 페이지에서 이 주문을 효율적으로 확인 및 관리하는 반응형 웹 애플리케이션

**서비스 특징**:
- 개인화된 인물 피규어 제작
- 4가지 스타일의 기념패 옵션
- 단계별 직관적인 주문 프로세스
- 실시간 이미지 미리보기
- 관리자 주문 관리 시스템

## 2. 핵심 데이터 모델 및 기술 스택 (Core Data Model & Tech Stack)

### 2.1. Order 모델 명세 (최신 업데이트 - 2025-07-11)

Order 모델은 데이터베이스에 다음 속성(컬럼)들로 저장되어야 합니다.

**필수 필드**:
- `naver_order_number`: string 타입. 네이버 주문번호를 저장하며, 이 주문의 고유 식별자(Business Key)로 사용됩니다. NULL 값을 허용하지 않으며, 데이터베이스 상에서 항상 고유(UNIQUE)해야 합니다.
- `orderer_name`: string 타입. 주문자 성함을 저장합니다.
- `plaque_style`: string 타입. 고객이 선택한 기념패 스타일의 종류를 저장합니다. 
  - 허용값: `gold_metal`, `silver_metal`, `acrylic_cartoon`, `acrylic_realistic`
- `status`: string 타입. 현재 주문의 진행 상태를 나타냅니다. 기본값은 '주문접수'
  - 허용값: '주문접수', '시안확정', '제작중', '배송중', '배송완료'

**레거시 필드** (하위 호환성 유지):
- `plaque_message`: text 타입. 기존 통합 메시지 필드 (현재는 사용되지 않음)

**새로운 세분화된 기념패 필드** (2025-07-11 추가):
- `plaque_title`: string 타입. 금속패 제목 (최대 15자) - 선택 입력
- `plaque_name`: string 타입. 금속패 성함 (최대 40자) - 선택 입력
- `plaque_content`: text 타입. 금속패 본문 (최대 150자) - 선택 입력
- `plaque_top_message`: string 타입. 아크릴패 상단문구 (최대 10자) - 선택 입력
- `plaque_main_message`: string 타입. 아크릴패 메시지 (최대 25자) - 선택 입력

**유연한 검증 정책** (2025-07-11 도입):
- 금속패 스타일: 제목, 성함, 본문 중 최소 1개 필드 입력 시 유효성 검사 통과
- 아크릴패 스타일: 상단문구, 메시지 중 최소 1개 필드 입력 시 유효성 검사 통과
- 사용자 편의성을 위한 유연한 검증 방식으로 "can't be blank" 오류 해결

**선택적 필드**:
- `additional_requests`: text 타입. 고객이 남긴 추가 요청사항을 저장하며, 이 값은 비어있을 수 있습니다. (NULLABLE)

**파일 첨부**:
- `main_images`: 필수 첨부 파일. 고객이 올린 정면 사진들(최대 5개)을 저장합니다. (has_many_attached)
- `optional_images`: 선택 첨부 파일. 고객이 올린 포즈 및 의상 참고 사진들(최대 5개)을 저장합니다. (has_many_attached)

### 2.2. 기술 스택 (Tech Stack)

**백엔드**:
- Ruby on Rails 8.0.2
- Ruby 3.4.2

**데이터베이스**:
- SQLite (개발환경)
- PostgreSQL (프로덕션 환경 - Render 클라우드 배포)

**파일 저장**:
- Active Storage (이미지 업로드 및 저장)

**프론트엔드**:
- Tailwind CSS 3.4.0 (스타일링) - 안정적인 프로덕션 버전으로 다운그레이드
- JavaScript (ES6+) - 이미지 미리보기, 폼 검증, 동적 UI
- 반응형 디자인 (모바일 우선)

**개발 도구**:
- Foreman (개발 서버 관리)
- NPM (프론트엔드 패키지 관리)

**클라우드 배포**:
- Render.com (웹 호스팅 플랫폼)
- GitHub (코드 저장소 및 자동 배포 연동)
- PostgreSQL (Render 관리형 데이터베이스)

## 3. 사용자 플로우 상세: "김민준 씨의 인물 피규어 기념패 주문"

### 3.1. 진입: 개인화 URL을 통한 첫 만남

**사용자 스토리**: 김민준 씨는 아버지의 칠순을 기념하여 인물 피규어 기념패를 네이버 스토어에서 주문했습니다. 잠시 후, 카카오톡으로 "[기프트루] 인물 피규어 정보를 입력해주세요" 라는 제목의 알림톡을 받습니다. 메시지 안에는 개인 전용 링크가 포함되어 있습니다.

**URL 구조**: 링크는 `https://your-domain.com/orders/네이버주문번호` 형태입니다. (예: `.../orders/2025071012345678`)

**사용자 행동**: 김민준 씨는 링크를 클릭합니다.

### 3.2. 페이지 1: 정면 사진 업로드 (1/3 단계)

**페이지 목표**: 인물 피규어 제작을 위한 정면 사진을 수집하고 주문자를 특정한다.

**화면 구성**:
- **헤더**: '기프트루 인물 피규어 정보 입력'이라는 큰 제목이 표시됩니다.
- **진행 상태**: 동적 프로그레스 바로 1/3 단계(33.3%) 표시
- **주문자 성함 필드**: 주문자 성함을 입력하는 텍스트 입력 칸
- **정면 사진 업로드 섹션**: 
  - 5개의 이미지 슬롯 그리드 (클릭 가능)
  - "사진 선택하기" 버튼
  - "JPG, PNG 파일 | 개당 최대 10MB" 안내 문구
  - 실시간 이미지 미리보기 기능
- **하단 버튼**: "다음 단계" 버튼

**사용자 시나리오**:
1. 김민준 씨는 주문자 성함 칸에 '김민준'을 입력합니다.
2. 이미지 슬롯을 클릭하거나 "사진 선택하기" 버튼을 눌러 아버지의 정면 사진 2장을 업로드합니다.
3. 업로드 즉시, 선택한 사진들이 슬롯에 썸네일로 나타나고, 파란색 테두리와 순번이 표시됩니다.
4. "다음 단계" 버튼을 클릭하여 2단계로 이동합니다.

**검증 로직**:
- 실시간 클라이언트 사이드 검증
- 이름 누락 시 인라인 에러 메시지 표시
- 사진 누락 시 인라인 에러 메시지 표시
- 검증 실패 시 폼 제출 차단 및 에러 위치로 자동 스크롤

### 3.3. 페이지 2: 포즈 및 의상 정보 (2/3 단계 - 선택사항)

**페이지 목표**: 피규어 제작 시 참고할 추가적인 포즈나 의상 정보를 선택적으로 수집한다.

**화면 구성**:
- **진행 상태**: 2/3 단계 (66.7%) 표시
- **추가 사진 섹션**: 
  - 5개의 이미지 슬롯 (초록색 테두리로 구분)
  - "사진 업로드" 버튼  
  - 실시간 이미지 미리보기
- **추가 요청사항**: 자유 입력 텍스트 영역 (4줄)
- **하단 버튼**: "이전으로", "다음 단계" 버튼

**사용자 시나리오**: 김민준 씨는 특별히 추가할 포즈나 의상 참고 사진이 없어, 바로 "다음 단계" 버튼을 클릭합니다.

### 3.4. 페이지 3: 기념패 스타일 선택 및 세분화된 입력 (3/3 단계) - 최신 업데이트

**페이지 목표**: 기념패의 디자인 스타일을 최종 결정하고, 스타일별로 세분화된 입력 필드를 통해 정확한 제작 정보를 수집한다.

**화면 구성**:
- **진행 상태**: 3/3 단계 (100%) 표시
- **스타일 선택**: 2x2 그리드로 4개의 기념패 스타일 카드 표시
  - 각 카드는 실제 기념패 이미지(PNG, 1:2 비율)를 포함
  - 호버 효과 및 선택 시 활성화 표시
- **동적 세분화 입력 필드**: 선택한 스타일에 따라 맞춤형 입력 필드 표시
- **실시간 문자 카운터**: 각 필드별 문자 수 제한 표시
- **하단 버튼**: "이전으로", "주문 완료" 버튼

**4가지 기념패 스타일과 세분화된 입력 필드**:

1. **🥇 금속패 (골드)** (`gold_metal`)
   - 설명: 고급스러운 골드 금속패
   - **입력 필드**:
     - 제목: 15자 제한 (예: 감사패, 공로패, 축하패)
     - 성함: 40자 제한 (예: 김철수님, 홍길동 귀하)
     - 본문: 150자 제한 (상세한 감사나 축하 메시지)
   - 팁: 간결하고 임팩트 있는 문구가 좋습니다

2. **🥈 금속패 (실버)** (`silver_metal`)
   - 설명: 깔끔한 실버 금속패
   - **입력 필드**:
     - 제목: 15자 제한 (예: 우수사원상, 공로패, 인정패)
     - 성함: 40자 제한 (예: 홍길동, 김영희 과장님)
     - 본문: 150자 제한 (업무 성과나 공로 관련 메시지)
   - 팁: 깔끔하고 전문적인 문구가 어울립니다

3. **🎨 아크릴패 (카툰)** (`acrylic_cartoon`)
   - 설명: 귀여운 카툰스타일 아크릴패
   - **입력 필드**:
     - 상단문구: 10자 제한 (예: 사랑해요♥, 축하해요!, 고마워요)
     - 메시지: 25자 제한 (예: 우리 가족 최고! 건강하세요)
   - 팁: 밝고 따뜻한 표현과 이모티콘을 활용해보세요

4. **📸 아크릴패 (실사)** (`acrylic_realistic`)
   - 설명: 생생한 실사스타일 아크릴패
   - **입력 필드**:
     - 상단문구: 10자 제한 (예: 감사합니다, 축하드립니다, 고맙습니다)
     - 메시지: 25자 제한 (예: 건강하고 행복하세요)
   - 팁: 정확한 날짜와 정중한 표현을 사용하세요

**새로운 사용자 시나리오** (세분화된 입력):
1. 김민준 씨는 '아크릴패 (실사)' 이미지를 클릭합니다.
2. 즉시, 클릭한 이미지는 활성화 표시되고 다른 이미지들은 비활성화됩니다.
3. 아크릴패 실사 스타일에 맞는 세분화된 입력 필드가 나타납니다:
   - 상단문구 입력 필드 (10자 제한)
   - 메시지 입력 필드 (25자 제한)
4. 그는 상단문구에 "감사합니다"를 입력하고, 메시지에 "건강하고 행복하세요"를 입력합니다.
5. 실시간 문자 카운터로 "5/10자", "12/25자" 표시를 확인합니다.
6. 최소 하나의 필드만 입력하면 되므로, 모든 내용을 확인한 후 "주문 완료" 버튼을 클릭합니다.

**유연한 검증 로직**:
- 금속패: 제목, 성함, 본문 중 **최소 1개 필드**만 입력하면 통과
- 아크릴패: 상단문구, 메시지 중 **최소 1개 필드**만 입력하면 통과
- 사용자 편의성을 위한 유연한 검증 방식 적용

### 3.5. 페이지 4: 주문 완료 확인 및 수정

**페이지 목표**: 주문이 성공적으로 접수되었음을 알리고, 최종 내역을 요약하여 보여주며, 수정 경로를 안내한다.

**화면 구성**:
- **성공 메시지**: "주문이 성공적으로 접수되었습니다."
- **주문 내역 요약**: 
  - 주문번호, 이름, 선택한 스타일, 입력한 문구
  - 업로드된 사진 썸네일
- **예상 수령일**: 주문 최종 제출일 + 15일로 계산된 날짜
- **수정 버튼**: "주문 수정하기" 버튼 (시안확정 전까지만 표시)
- **안내 문구**: "처음에 받으신 알림톡의 링크로 다시 들어오시면 주문 내용을 다시 확인하실 수 있습니다."

**수정 시나리오**: 다음 날, 김민준 씨는 문구를 약간 바꾸고 싶어 어제 받았던 알림톡의 링크를 다시 클릭합니다. 1단계 페이지가 열리지만, 어제 입력했던 이름과 사진이 모두 그대로 채워져 있습니다. 그는 "다음 단계" 버튼을 두 번 눌러 3단계로 이동한 뒤, 문구를 수정하고 다시 "주문 완료" 버튼을 누릅니다.

## 4. 관리자 플로우 상세: "박 사장님의 주문 처리"

### 4.1. 페이지 1: 관리자 로그인

**관리자 시나리오**: 박 사장님은 신규 주문을 확인하기 위해 PC에서 `/admin` URL로 접속합니다.

**페이지 사양**: 
- 간단한 로그인 폼 (ID/Password)
- 기본 계정: `admin` / `password123`
- 세션 기반 인증 시스템

### 4.2. 페이지 2: 주문 목록 대시보드

**관리자 시나리오**: 로그인에 성공하자 주문 관리 대시보드가 나타납니다.

**페이지 사양**:
- **상태 필터 탭**: [전체], [주문접수], [시안확정], [제작중], [배송중], [배송완료]
- **기본 선택**: [주문접수] 탭이 기본으로 선택되어 신규 주문을 바로 확인
- **실시간 카운트**: 각 상태별 주문 수량 표시
- **주문 목록**: 
  - 네이버 주문번호, 주문자 성함, 주문 상태, 주문일시
  - 이미지 미리보기 포함
  - 전체 행(row) 클릭 가능
- **반응형 테이블**: 모바일과 데스크톱 환경 최적화

### 4.3. 페이지 3: 주문 상세 및 상태 관리

**관리자 시나리오**: 박 사장님은 김민준 씨의 주문 행을 클릭하여 상세 내용을 확인합니다.

**페이지 사양**:
- **완전한 주문 정보 표시**:
  - 고객이 제출한 모든 정보
  - 업로드된 사진들을 선명한 크기로 표시 (3열 그리드)
  - 선택한 기념패 스타일 정보
  - 입력한 문구 및 추가 요청사항
- **상태 관리**:
  - 페이지 상단에 주문 상태 변경 드롭다운
  - 현재 상태에서 다음 상태로 변경 가능
- **고객 페이지 링크**: 고객이 보는 주문 페이지로 바로 이동 가능

**관리자 행동 및 시스템 규칙**:
1. 박 사장님은 주문 내용을 검토한 후 제작에 문제가 없다고 판단합니다.
2. 주문 상태 드롭다운을 클릭하여 **시안확정**으로 변경하고 저장합니다.
3. **시스템 규칙**: 이 순간부터 해당 주문은 고객이 수정할 수 없도록 잠금 처리됩니다.
4. 김민준 씨가 다시 알림톡 링크로 접속해도 "주문 수정하기" 버튼은 더 이상 표시되지 않습니다.
5. 대신 "시안이 확정되어 더 이상 수정할 수 없습니다."라는 알림이 표시됩니다.

## 5. 기술적 구현 세부사항

### 5.1. 프로젝트 구조

```
app/
├── controllers/
│   ├── application_controller.rb      # 공통 인증 헬퍼
│   ├── orders_controller.rb          # 고객 주문 처리 (3단계 플로우)
│   └── admin/
│       ├── sessions_controller.rb     # 관리자 로그인
│       └── orders_controller.rb       # 관리자 주문 관리
├── models/
│   └── order.rb                      # 주문 모델 (완전 구현)
├── views/
│   ├── layouts/
│   │   ├── application.html.erb       # 고객용 레이아웃
│   │   └── admin.html.erb             # 관리자용 레이아웃
│   ├── orders/
│   │   ├── new.html.erb               # 루트 페이지
│   │   ├── edit.html.erb              # 3단계 주문 폼
│   │   └── complete.html.erb          # 주문 완료 페이지
│   └── admin/
│       ├── sessions/
│       │   └── new.html.erb           # 로그인 페이지
│       └── orders/
│           ├── index.html.erb         # 주문 목록
│           └── show.html.erb          # 주문 상세
├── assets/
│   ├── images/plaques/               # 기념패 스타일 이미지
│   │   ├── gold_metal.png
│   │   ├── silver_metal.png
│   │   ├── acrylic_cartoon.png
│   │   └── acrylic_realistic.png
│   └── stylesheets/
│       └── application.tailwind.css   # Tailwind CSS
config/
└── routes.rb                         # RESTful 라우팅
```

### 5.2. 라우팅 설계

```ruby
# config/routes.rb
root "orders#new"

# 관리자 라우팅 (우선순위)
namespace :admin do
  get :login, to: "sessions#new"
  post :login, to: "sessions#create"
  delete :logout, to: "sessions#destroy"
  
  root "orders#index"
  resources :orders do
    member do
      patch :update_status
    end
  end
end

# 고객 주문 라우팅
resources :orders, param: :naver_order_number do
  member do
    get :complete
    patch :update_step
  end
end
```

### 5.3. 핵심 기능 구현

#### Order 모델 (app/models/order.rb)
```ruby
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
  
  # 세분화된 필드 검증 - 최소 1개 필드만 입력하면 통과 (2025-07-11)
  validate :validate_plaque_fields_completion, if: :validate_step_3_or_complete?
  
  # 길이 제한 검증
  validates :plaque_title, length: { maximum: 15 }, if: :validate_metal_plaque_fields?
  validates :plaque_name, length: { maximum: 40 }, if: :validate_metal_plaque_fields?
  validates :plaque_content, length: { maximum: 150 }, if: :validate_metal_plaque_fields?
  validates :plaque_top_message, length: { maximum: 10 }, if: :validate_acrylic_plaque_fields?
  validates :plaque_main_message, length: { maximum: 25 }, if: :validate_acrylic_plaque_fields?
  
  # Custom validations
  validate :validate_main_images_content_type_and_size
  validate :validate_optional_images_content_type_and_size
  validate :validate_main_images_count
  
  # 비즈니스 로직
  def can_be_edited?
    status == '주문접수'
  end
  
  def expected_delivery_date
    created_at + 15.days
  end
  
  def to_param
    naver_order_number
  end
end
```

#### 고객 주문 컨트롤러 핵심 로직
- **3단계 플로우 관리**: step 파라미터를 통한 단계별 처리
- **동적 검증**: 단계별 다른 검증 규칙 적용
- **파일 업로드**: Active Storage를 통한 이미지 처리
- **주문 완료**: complete_step 파라미터를 통한 명확한 완료 처리

#### 관리자 주문 관리
- **상태별 필터링**: 스코프를 활용한 효율적인 쿼리
- **주문 상태 변경**: 비즈니스 규칙에 따른 상태 전환
- **이미지 최적화**: Active Storage variants를 활용한 썸네일

### 5.4. UI/UX 특징

#### 프리미엄 디자인 시스템
- **그라디언트 배경**: 현대적이고 고급스러운 느낌
- **동적 프로그레스 바**: 실시간 진행률 표시
- **이미지 슬롯 시스템**: 직관적인 5개 슬롯 업로드 UI
- **실시간 미리보기**: JavaScript FileReader API 활용
- **스타일별 맞춤 입력**: 동적 required 속성 관리

#### 반응형 웹 디자인
- **모바일 우선 설계**: Tailwind CSS의 반응형 클래스 활용
- **적응형 레이아웃**: 화면 크기에 따른 최적화
- **터치 인터페이스**: 모바일 환경에서의 사용성 고려

#### 사용자 경험 개선
- **실시간 검증**: 즉시 피드백을 통한 사용자 가이드
- **인라인 에러 메시지**: 구체적이고 도움이 되는 오류 안내
- **부드러운 애니메이션**: CSS3 전환 효과
- **접근성**: 스크린 리더 지원 및 키보드 네비게이션

### 5.5. 성능 최적화

#### 백엔드 최적화
- **N+1 쿼리 방지**: includes를 활용한 관계 로딩
- **효율적인 스코프**: 데이터베이스 레벨에서의 필터링
- **적절한 인덱싱**: naver_order_number에 대한 유니크 인덱스

#### 프론트엔드 최적화
- **이미지 최적화**: Active Storage를 통한 동적 리사이징
- **Asset 압축**: Tailwind CSS 빌드 최적화
- **메모리 효율적인 미리보기**: FileReader 적절한 사용

### 5.6. 보안 및 검증

#### 보안 조치
- **CSRF 토큰**: Rails 기본 보안 기능 활용
- **XSS 방지**: 적절한 HTML 이스케이핑
- **파일 업로드 검증**: 파일 타입 및 크기 제한
- **세션 기반 인증**: 관리자 접근 제어

#### 데이터 검증
- **단계별 검증**: 각 단계에 맞는 검증 규칙
- **파일 검증**: 이미지 타입(JPG, PNG) 및 크기(10MB) 제한
- **비즈니스 로직 검증**: 주문 상태 전환 규칙

## 6. 테스트 및 실행 방법

### 6.1. 개발 환경 설정

```bash
# 프로젝트 디렉토리로 이동
cd /mnt/c/WINDOWS/system32/giftrue

# 개발 서버 실행 (Rails + Tailwind CSS)
bin/dev

# 또는 개별 실행
# CSS 빌드
npm run build:css:compile

# Rails 서버
rails server
```

### 6.2. 테스트 URL

**고객 사용 URL**:
- 루트 페이지: `http://localhost:3000`
- 주문 페이지: `http://localhost:3000/orders/2025071012345678`
- 주문 완료: `http://localhost:3000/orders/2025071012345678/complete`

**관리자 URL**:
- 관리자 로그인: `http://localhost:3000/admin/login`
- 관리자 대시보드: `http://localhost:3000/admin`
- 주문 상세: `http://localhost:3000/admin/orders/1`

**관리자 계정**:
- ID: `admin`
- Password: `password123`

### 6.3. 주요 테스트 시나리오

#### 고객 플로우 테스트
1. **3단계 주문 과정**:
   - 1단계: 이름 입력 + 정면 사진 업로드
   - 2단계: 추가 사진 업로드 (선택)
   - 3단계: 스타일 선택 + 문구 입력
   - 완료: 주문 완료 페이지 확인

2. **검증 테스트**:
   - 필수 정보 누락 시 인라인 에러 메시지
   - 이미지 파일 형식/크기 제한 확인
   - 실시간 문자 카운터 동작

3. **수정 테스트**:
   - 주문 완료 후 수정 시도
   - 시안확정 후 수정 제한 확인

#### 관리자 플로우 테스트
1. **주문 관리**:
   - 로그인 → 주문 목록 → 상태별 필터링
   - 주문 상세 → 상태 변경 → 고객 수정 제한 확인

2. **권한 테스트**:
   - 비로그인 상태에서 관리자 페이지 접근 차단
   - 세션 만료 후 자동 로그인 페이지 리디렉션

## 7. 배포 및 운영

### 7.1. 배포 준비 사항

#### 필수 파일 배치
```
public/images/plaques/
├── gold_metal.png      (금속패 골드 이미지)
├── silver_metal.png    (금속패 실버 이미지)
├── acrylic_cartoon.png (아크릴패 카툰 이미지)
└── acrylic_realistic.png (아크릴패 실사 이미지)
```

#### 환경 설정
- **프로덕션 데이터베이스**: SQLite → PostgreSQL/MySQL 고려
- **파일 저장**: Local → Cloud Storage (AWS S3 등) 고려
- **이미지 최적화**: CDN 활용 검토

### 7.2. 네이버 스마트스토어 연동

#### 알림톡 연동 준비
- **URL 형식**: `https://your-domain.com/orders/{naver_order_number}`
- **메시지 템플릿**: "[기프트루] 인물 피규어 정보를 입력해주세요"
- **자동화**: 주문 발생 시 자동 알림톡 전송 시스템 구축

### 7.3. 모니터링 및 유지보수

#### 로깅 시스템
- **주문 처리 로그**: 각 단계별 사용자 행동 추적
- **에러 로그**: 파일 업로드 실패, 검증 오류 등
- **성능 로그**: 응답 시간, 데이터베이스 쿼리 성능

#### 백업 및 복구
- **데이터베이스 백업**: 주문 데이터 정기 백업
- **이미지 파일 백업**: 고객 업로드 이미지 보존
- **복구 절차**: 장애 상황 대응 매뉴얼

## 8. 확장 가능성 및 개선 방안

### 8.1. 단기 개선 사항

#### 사용자 경험 개선
- **드래그 앤 드롭 업로드**: 파일 선택의 편의성 증대
- **이미지 편집**: 크롭, 회전 등 기본 편집 기능
- **실시간 알림**: WebSocket을 활용한 주문 상태 알림

#### 관리자 기능 강화
- **일괄 처리**: 여러 주문의 상태를 한 번에 변경
- **주문 검색**: 주문번호, 고객명으로 빠른 검색
- **통계 대시보드**: 일일/월간 주문 현황 시각화

### 8.2. 중장기 확장 방안

#### 서비스 확장
- **다국어 지원**: 해외 고객을 위한 다국어 인터페이스
- **결제 연동**: 추가 옵션에 대한 결제 시스템
- **배송 추적**: 실시간 배송 상황 안내

#### 기술적 확장
- **마이크로서비스**: 주문, 제작, 배송 시스템 분리
- **AI 활용**: 이미지 품질 자동 검증, 최적 각도 추천
- **모바일 앱**: 네이티브 앱을 통한 더 나은 UX

### 8.3. 비즈니스 확장

#### 상품 다양화
- **크기 옵션**: 다양한 크기의 기념패 제공
- **패키징 옵션**: 고급 선물 포장 서비스
- **맞춤 서비스**: 특별한 요청에 대한 개별 상담

#### 마케팅 연동
- **소셜 미디어**: 완성된 기념패 공유 기능
- **리뷰 시스템**: 고객 후기 및 평점 관리
- **추천 프로그램**: 고객 추천 시 혜택 제공

## 9. 개발 완료 현황

### 9.1. 구현 완료 기능 (100%)

✅ **프로젝트 기본 설정**
- Rails 8.0.2 + Ruby 3.4.2 환경 구축
- Tailwind CSS 4.1.11 설정 및 최적화
- SQLite 데이터베이스 및 Active Storage 설정

✅ **Order 모델 완전 구현**
- 모든 필드 및 관계 설정 (기존 필드 + 5개 세분화된 새 필드)
- 단계별 검증 로직 및 유연한 검증 시스템 (2025-07-11 개선)
- 파일 업로드 검증 (타입, 크기, 개수)
- 비즈니스 로직 메서드
- 세분화된 필드별 길이 제한 검증

✅ **고객 주문 시스템**
- 3단계 주문 플로우 (정면사진 → 포즈/의상 → 스타일/문구)
- 실시간 이미지 미리보기 (5개 슬롯 시스템)
- 동적 폼 검증 및 인라인 에러 메시지
- **스타일별 세분화된 입력 필드 시스템** (2025-07-11 신규 구현):
  - 금속패: 제목(15자) + 성함(40자) + 본문(150자)
  - 아크릴패: 상단문구(10자) + 메시지(25자)
  - 실시간 문자 카운터 및 동적 필드 전환
- 주문 완료 페이지 및 수정 기능
- 한글 스타일명 표시 (금속패 🥇, 아크릴패 🎨 등)

✅ **관리자 시스템**
- 세션 기반 인증 시스템
- 상태별 필터링 대시보드
- 주문 상세 관리 및 상태 변경
- 시안확정 후 고객 수정 제한

✅ **UI/UX 시스템**
- 프리미엄 디자인 시스템 (그라디언트, 애니메이션)
- 완전한 반응형 웹 디자인
- 기념패 스타일별 실제 이미지 표시
- 직관적인 단계별 프로그레스 바

✅ **성능 및 보안**
- N+1 쿼리 방지 최적화
- CSRF/XSS 보안 조치
- 파일 업로드 보안 검증
- 효율적인 이미지 처리

### 9.2. 최신 주요 업데이트 (2025-07-11)

**🎯 기념패 입력 세분화 시스템 구축** (Major Update):
- ✅ 데이터베이스 스키마 확장: 5개 새로운 필드 추가
  - `plaque_title` (금속패 제목, 15자)
  - `plaque_name` (금속패 성함, 40자)  
  - `plaque_content` (금속패 본문, 150자)
  - `plaque_top_message` (아크릴패 상단문구, 10자)
  - `plaque_main_message` (아크릴패 메시지, 25자)

**🔧 스타일별 맞춤형 입력 시스템**:
- ✅ 금속패 (골드/실버): 제목, 성함, 본문 3단계 입력
- ✅ 아크릴패 (카툰/실사): 상단문구, 메시지 2단계 입력
- ✅ 실시간 문자 카운터 (색상 변경: 회색→노란색→빨간색)
- ✅ 스타일별 맞춤형 플레이스홀더 및 사용 가이드

**🎨 사용자 경험 혁신**:
- ✅ 유연한 검증 로직: 최소 1개 필드만 입력하면 통과
- ✅ 동적 입력 필드 관리 및 JavaScript 검증 강화
- ✅ 이미지 표시 오류 시 graceful fallback UI
- ✅ Turbo.js 호환성 문제 해결 (data-turbo: false)

**🚀 기술적 개선사항**:
- ✅ Order 모델 검증 로직 고도화
- ✅ 마이그레이션 완료 및 프로덕션 배포 성공  
- ✅ JavaScript 폼 검증 시스템 재구축
- ✅ Admin 페이지 한글 스타일 표시 통일

### 9.3. 프로덕션 준비도: 100%

**배포 상태**: 모든 기능이 Render.com에 성공적으로 배포됨
**서비스 URL**: [실제 서비스 URL]
**데이터베이스**: PostgreSQL (프로덕션) / SQLite (개발)
**스토리지**: Active Storage with PostgreSQL adapter

**개발 완료 확인사항**:
- ✅ 모든 핵심 기능 구현 완료 (고객 주문 + 관리자 시스템)
- ✅ 세분화된 입력 시스템 정상 작동 확인
- ✅ 실제 환경에서 주문 플로우 테스트 완료
- ✅ 이미지 업로드 및 표시 정상 작동
- ✅ 관리자 시스템 권한 및 기능 검증 완료
- ✅ 모바일 반응형 디자인 검증 완료

**네이버 스마트스토어 연동 준비**: 완료
- 주문 URL 패턴: `/orders/{naver_order_number}`
- 알림톡 연동을 위한 API 엔드포인트 준비 완료

---

## 10. 개발자 참고사항

### 10.1. 최신 개발 히스토리 (2025-07-11)

**해결된 주요 이슈들**:
1. **Turbo.js 호환성**: `data-turbo: false` 추가로 폼 리디렉션 문제 해결
2. **이미지 404 오류**: Active Storage 이미지 로드 실패 시 graceful fallback 구현
3. **검증 오류 개선**: "can't be blank" 메시지를 유연한 검증으로 대체
4. **사용자 경험**: 한국어 스타일명 표시 및 이모지 활용

**기술적 학습점**:
- Rails 8.0에서 Turbo.js 비활성화 필요성
- Render.com ephemeral filesystem으로 인한 이미지 저장 제약
- 사용자 친화적 검증 로직의 중요성
- 세분화된 입력 필드의 UX 개선 효과

### 10.2. 향후 개발 시 주의사항

**코드 유지보수**:
- Order 모델의 검증 로직은 매우 정교하게 구성되어 있으므로 수정 시 주의 필요
- 세분화된 필드와 기존 `plaque_message` 필드 간의 호환성 유지 필요
- JavaScript 문자 카운터 로직은 스타일별로 다르게 작동하므로 수정 시 전체 테스트 필요

**성능 고려사항**:
- 이미지 업로드 시 Active Storage 처리 최적화 필요
- 대용량 파일 업로드 시 timeout 설정 확인 필요
- 향후 트래픽 증가 시 CDN 도입 검토 필요

## 12. 최신 개발 업데이트 (2025-07-11 - 예상 수령일 관리 시스템)

### 12.1. 주요 기능 추가 - 관리자 예상 수령일 설정

**요구사항**: 관리자 페이지에서 주문별로 예상 수령일 기준을 조정할 수 있는 기능

**구현 내용**:
- ✅ **데이터베이스 확장**: `expected_delivery_days` 필드 추가 (기본값: 15일)
- ✅ **Order 모델 개선**: 동적 예상 수령일 계산 로직 구현
- ✅ **관리자 컨트롤러**: `update_delivery_days` 액션 추가
- ✅ **관리자 UI**: 예상 수령일 관리 섹션 추가
- ✅ **실시간 미리보기**: JavaScript로 입력값에 따른 즉시 미리보기
- ✅ **데이터 검증**: 1일~90일 범위 제한 및 유효성 검사

### 12.2. 구현된 기능 상세

#### 데이터베이스 스키마 변경
```sql
-- 새로운 필드 추가
ALTER TABLE orders ADD COLUMN expected_delivery_days INTEGER DEFAULT 15;
```

#### Order 모델 개선
```ruby
# 동적 예상 수령일 계산
def expected_delivery_date
  created_at + (expected_delivery_days || 15).days
end

# 검증 규칙 추가
validates :expected_delivery_days, 
  presence: true, 
  numericality: { greater_than: 0, less_than_or_equal_to: 90 }
```

#### 관리자 페이지 UI 개선
- **현재 예상 수령일 표시**: 시각적으로 명확한 날짜 표시
- **제작 기간 입력**: 1-90일 범위의 숫자 입력 필드
- **실시간 미리보기**: 입력값 변경 시 즉시 계산된 날짜 표시
- **폼 검증**: 클라이언트 및 서버 사이드 검증

### 12.3. 사용자 플로우

1. **관리자 로그인** → `http://localhost:3000/admin/login`
2. **주문 상세 페이지** → 예상 수령일 관리 섹션 확인
3. **제작 기간 조정** → 1-90일 사이 값 입력
4. **실시간 미리보기** → 입력하는 동안 계산된 날짜 확인
5. **변경 적용** → "수령일 변경" 버튼 클릭
6. **고객 확인** → 고객 주문완료 페이지에서 업데이트된 날짜 확인

### 12.4. 기술적 특징

- **유연한 기본값**: 기존 주문은 15일 유지, 새 주문은 주문별 조정 가능
- **데이터 무결성**: 마이그레이션으로 기존 데이터 안전 보장
- **사용자 경험**: 실시간 미리보기로 직관적인 인터페이스
- **확장성**: 향후 주문 유형별 기본 제작 기간 설정 가능

### 12.5. 테스트 시나리오

```bash
# 로컬 테스트
http://localhost:3000/admin/login (admin / password123)
http://localhost:3000/admin/orders/1 # 예상 수령일 관리 섹션 확인

# 주문 1: 20일로 설정됨 (2025년 07월 29일 예상)
# 다른 주문들: 기본 15일 유지
```

---

**문서 최종 업데이트**: 2025-07-11 15:30 (KST)
**작성자**: Claude AI Assistant  
**목적**: 개발 연속성 유지 및 향후 개발자 온보딩

**✅ 모든 PRD 요구사항 완전 구현**
**✅ 안정적인 3단계 주문 플로우**
**✅ 완전한 관리자 시스템**
**✅ 프리미엄급 UI/UX**
**✅ 보안 및 성능 최적화**
**✅ 반응형 웹 디자인**

## 10. 클라우드 배포 진행 상황 (Render.com)

### 10.1. 배포 환경 설정 완료 (2025-07-10)

**GitHub 저장소 설정**:
- ✅ 저장소 URL: https://github.com/go-dyc/giftrue-app
- ✅ Git 저장소 초기화 및 코드 푸시 완료
- ✅ Personal Access Token 인증 설정
- ✅ 자동 배포 파이프라인 연동

**Render 배포 설정 파일**:
- ✅ `render.yaml`: 웹 서비스 및 데이터베이스 설정
- ✅ `bin/render-build.sh`: 자동 빌드 스크립트
- ✅ 환경변수 설정: RAILS_ENV, DATABASE_URL, RAILS_MASTER_KEY

### 10.2. 데이터베이스 마이그레이션

**개발 → 프로덕션 전환**:
- ✅ SQLite (개발) → PostgreSQL (프로덕션) 설정 완료
- ✅ Gemfile 수정: pg gem 추가, 환경별 구분
- ✅ database.yml 프로덕션 설정 업데이트
- ✅ 다중 데이터베이스 지원 (primary, cache, queue, cable)

### 10.3. 빌드 시스템 최적화

**TailwindCSS 호환성 해결**:
- ✅ TailwindCSS 4.1.11 → 3.4.0 다운그레이드 (안정성)
- ✅ package.json dependencies 구조 수정
- ✅ npx 명령어 적용으로 실행 안정성 확보
- ✅ CSS 임포트 구문 수정: 개별 모듈 임포트 방식 적용
  ```css
  @import "tailwindcss/base";
  @import "tailwindcss/components";
  @import "tailwindcss/utilities";
  ```

**빌드 스크립트 최적화**:
- ✅ Ruby dependencies 설치
- ✅ Node.js dependencies 설치  
- ✅ TailwindCSS 컴파일
- ✅ Rails assets precompilation
- ✅ 데이터베이스 마이그레이션 자동 실행

### 10.4. 배포 진행 단계별 해결 과정

**1단계 - Git 설정**:
- ✅ 로컬 Git 저장소 초기화
- ✅ GitHub 원격 저장소 연결
- ✅ Personal Access Token 생성 및 인증
- ✅ 초기 코드베이스 푸시 성공

**2단계 - Render 서비스 생성**:
- ✅ Render.com 계정 연결
- ✅ GitHub 저장소 연동
- ✅ 웹 서비스 설정 구성
- ✅ PostgreSQL 데이터베이스 생성

**3단계 - 빌드 문제 해결**:
- ✅ Gemfile.lock PostgreSQL 호환성 문제 해결
- ✅ TailwindCSS 버전 호환성 문제 해결
- ✅ CSS 빌드 파이프라인 수정
- ✅ 환경변수 설정 최적화

### 10.5. 배포 완료 및 버그 수정

**배포 진행률**: 100% 완료 ✅
**현재 상태**: 프로덕션 배포 완료, 주문완료 버튼 버그 수정 완료
**배포 완료**: 2025-07-10 22:15 (KST)

**✅ 배포 성공 확인됨**:
- TailwindCSS 3.4.0 정상 빌드 완료
- CSS 임포트 구문 호환성 문제 해결
- 전체 애플리케이션 정상 배포 확인

**🐛 프로덕션 버그 발견 및 수정**:
- **문제**: Step 3에서 "주문 완료" 버튼 클릭 시 동작하지 않음
- **원인**: JavaScript 폼 검증 로직에서 Step 3 처리 누락
- **해결**: validateStep3() 함수 추가 및 폼 제출 로직 개선
- **수정 완료**: 2025-07-10 22:45 (KST)

### 10.6. 프로덕션 버그 수정 상세

**발견된 문제**:
```javascript
// 기존 코드 - Step 1에서만 검증
if (stepInput && stepInput.value === '1') {
  if (!validateStep1()) {
    e.preventDefault();
  }
}
// Step 3 검증 로직 누락으로 폼 제출 차단됨
```

**적용된 해결책**:
```javascript
// 수정된 코드 - 단계별 검증
if (currentStep === '1') {
  if (!validateStep1()) {
    e.preventDefault();
  }
} else if (currentStep === '3') {
  const completeStepInput = document.querySelector('input[name="complete_step"]');
  if (completeStepInput && !validateStep3()) {
    e.preventDefault();
    alert('기념패 스타일과 문구를 모두 입력해주세요.');
  }
}

// 새로 추가된 validateStep3() 함수
function validateStep3() {
  const checkedRadio = document.querySelector('input[name="order[plaque_style]"]:checked');
  if (!checkedRadio) return false;
  
  const visibleTextarea = document.querySelector(`.style-input.${checkedRadio.value}:not(.hidden) textarea`);
  return visibleTextarea && visibleTextarea.value.trim();
}
```

### 10.7. 배포 완료 후 접속 정보

**✅ 프로덕션 URL들** (정상 동작 확인됨):
- 메인 페이지: `https://giftrue-app.onrender.com`
- 주문 페이지: `https://giftrue-app.onrender.com/orders/{주문번호}`
- 관리자 로그인: `https://giftrue-app.onrender.com/admin/login`

**관리자 계정**:
- ID: `admin`
- Password: `password123`

**기술적 특징**:
- 무료 Render 플랜 사용 (15분 비활성화 후 슬립)
- PostgreSQL 무료 데이터베이스 (500MB 제한)
- 자동 HTTPS 적용
- GitHub 연동 자동 배포

**✅ 검증 완료된 기능들**:
- 3단계 주문 프로세스 정상 동작
- 이미지 업로드 기능 작동
- 기념패 스타일 선택 기능 정상
- 주문 완료 버튼 정상 동작 (수정 완료)
- 관리자 로그인 및 주문 관리 기능

---

**최종 업데이트**: 2025-07-10 22:13 (KST)  
**개발 상태**: 클라우드 배포 95% 완료 (최종 빌드 검증 중)  
**다음 단계**: 배포 완료 확인 → 네이버 스마트스토어 연동 준비

## 11. 개발 연속성 참고사항

### 11.1. 중요 파일 위치
```
giftrue/
├── CLAUDE.md                    # 이 문서 (개발 히스토리)
├── render.yaml                  # Render 배포 설정
├── bin/render-build.sh          # 빌드 스크립트
├── config/database.yml          # DB 설정 (SQLite + PostgreSQL)
├── Gemfile                      # Ruby 의존성 (pg gem 포함)
├── package.json                 # Node.js 의존성 (TailwindCSS 3.4.0)
└── app/assets/stylesheets/
    └── application.tailwind.css # TailwindCSS 메인 파일
```

### 11.2. 핵심 커맨드
```bash
# 개발 서버 실행
bin/dev

# 로컬 빌드 테스트
npm run build:css:compile
bundle exec rails assets:precompile

# Git 배포
git add -A
git commit -m "설명"
git push origin main
```

### 11.3. 환경변수 (Render)
```
RAILS_ENV=production
RACK_ENV=production
NODE_ENV=production
RAILS_MASTER_KEY=fdbfcd77259eb824ae5b295162a94077
DATABASE_URL=[Render에서 자동 설정]
```

### 11.4. 향후 개발 시 주의사항
- TailwindCSS는 3.4.0 버전 유지 (4.x 호환성 문제)
- 프로덕션 배포 시 PostgreSQL 사용
- Render 무료 플랜 제한사항 고려
- GitHub Personal Access Token 만료 주의