# CLAUDE.md

## 프로젝트 정보

- **프로젝트명**: giftrue - 네이버 주문 연동형 인물 피규어 기념패 제작 서비스
- **유형**: 인물 피규어 기념패 제작 서비스
- **프레임워크**: Ruby on Rails 8.0.2
- **Ruby 버전**: 3.4.2
- **CSS 프레임워크**: TailwindCSS 3.4.0
- **데이터베이스**: SQLite (개발), PostgreSQL (프로덕션)
- **배포**: DigitalOcean + Kamal + Docker

## 핵심 개념

**서비스 목표**: 네이버 스마트스토어 주문 고객이 알림톡으로 받은 개인화 URL을 통해 3단계 폼으로 인물 피규어 기념패 제작 정보를 입력하고, 관리자가 효율적으로 주문을 관리하는 반응형 웹 애플리케이션

## 핵심 데이터 모델

### Order 모델 명세

**필수 필드**:
- `naver_order_number`: string 타입, 고유 식별자 (UNIQUE, NOT NULL)
- `orderer_name`: string 타입, 주문자 성함 (단계별 검증)
- `plaque_style`: string 타입, 기념패 스타일
  - 허용값: `gold_metal`, `silver_metal`, `acrylic_cartoon`, `acrylic_realistic`
- `status`: string 타입, 주문 상태 (기본값: '주문접수')
  - 허용값: '주문접수', '시안확정', '제작중', '배송중', '배송완료', '주문취소'

**세분화된 기념패 필드**:
- `plaque_title`: string (최대 15자) - 금속패 제목
- `plaque_name`: string (최대 40자) - 금속패 성함  
- `plaque_content`: text (최대 150자) - 금속패 본문
- `plaque_top_message`: string (최대 10자) - 아크릴패 상단문구
- `plaque_main_message`: string (최대 25자) - 아크릴패 메시지

**파일 첨부**:
- `main_images`: 필수. 정면 사진 (최대 5개, JPG/PNG, 10MB 제한)
- `optional_images`: 필수. 포즈/의상 사진 (최대 5개)

**유연한 검증 정책**:
- 금속패: 제목, 성함, 본문 중 최소 1개 필드 입력 시 통과
- 아크릴패: 상단문구, 메시지 중 최소 1개 필드 입력 시 통과

**주문 취소 관련 필드** (2025-07-20 추가):
- `cancelled_at`: datetime, 주문 취소 일시
- `cancellation_reason`: text, 취소 사유
- `last_api_polled_at`: datetime, 마지막 API 폴링 시간

**선택적 필드**:
- `additional_requests`: text, 추가 요청사항
- `expected_delivery_days`: integer, 예상 배송일 (시스템 기본값 적용)

### SystemSetting 모델
- `key`: 설정 키 (예: default_delivery_days)
- `value`: 설정 값
- `description`: 설정 설명

## 사용자 플로우 (3단계 폼)

### 1단계: 정면 사진 업로드
**목표**: 인물 피규어 제작을 위한 정면 사진 수집 및 주문자 특정
- 주문자 성함 입력 (필수)
- 정면 사진 업로드 (필수, 최대 5개)
- 실시간 이미지 미리보기, 파일 형식/크기 검증
- 프로그레스 바: 1/3 (33.3%)

### 2단계: 포즈 및 의상 정보  
**목표**: 피규어 제작 참고용 추가 정보 수집 (필수 단계)
- 포즈/의상 참고 사진 업로드 (필수, 최대 5개)
- 추가 요청사항 입력 (선택적, 자유 텍스트)
- 프로그레스 바: 2/3 (66.7%)

### 3단계: 기념패 스타일 선택 및 입력
**목표**: 기념패 디자인 스타일 결정 및 세분화된 제작 정보 수집
- **4가지 기념패 스타일** (2x2 그리드, 실제 이미지 포함):
  - 🥇 금속패 (골드): 고급스러운 골드 금속패
  - 🥈 금속패 (실버): 깔끔한 실버 금속패  
  - 🎨 아크릴패 (카툰): 귀여운 카툰스타일
  - 📸 아크릴패 (실사): 생생한 실사스타일
- **동적 세분화 입력**: 선택한 스타일에 따라 맞춤형 입력 필드 표시
- **실시간 문자 카운터**: 각 필드별 제한 표시
- 프로그레스 바: 3/3 (100%)

### 완료 페이지
**목표**: 주문 완료 확인 및 정보 안내
- 주문 정보 요약 (주문번호, 선택한 스타일, 예상 배송일 등)
- **추가요청사항 통합 표시**: 일반 요청사항과 기념패 추가요청사항 모두 표시
- 성함 인증 후 접근 (1시간 세션, 공백 처리 자동화)
- 진행 상황 안내 및 연락처 정보

## 관리자 기능

### 주문 관리 (/admin)
- **주문 목록**: 상태별 필터링, 정렬, 페이지네이션
- **주문 상세**: 전체 정보 확인, 이미지 다운로드, 상태 변경
- **주문 삭제**: 3단계 안전 확인 시스템으로 완전 삭제 가능
- **대시보드**: 주문 현황 통계 및 요약

### 주문 삭제 시스템
**보안 강화된 3단계 확인 시스템**:
1. **1단계**: 주문 상세페이지에서 "주문 삭제 (클릭해서 시작)" 버튼 클릭
2. **2단계**: 주문번호 정확히 입력 (타이핑 필요, 복사 불가)
3. **3단계**: 브라우저 최종 확인 다이얼로그

**안전장치**:
- 주문 목록에서 삭제 버튼 완전 제거 (상세페이지에서만 가능)
- 주문번호 입력 전까지 삭제 버튼 비활성화
- 실시간 입력값 검증 및 피드백
- 각 단계에서 취소 가능
- 삭제 후 같은 주문번호로 새 주문 생성 가능

### 시스템 설정 (/admin/settings)
- 기본 배송일 설정
- 기타 시스템 설정 관리

### 보안
- 관리자 로그인 (/admin/login) - 세션 기반 인증
- 주문자 성함 인증 시 공백 처리 자동화 (앞뒤 공백 제거)

## 기술 스택 및 구현

**백엔드**: Ruby on Rails 8.0.2, Ruby 3.4.2, Active Storage
**프론트엔드**: TailwindCSS 3.4.0, JavaScript (ES6+), 반응형 디자인
**데이터베이스**: SQLite (개발), PostgreSQL (프로덕션)
**배포**: DigitalOcean + Kamal + Docker

### 핵심 검증 시스템
- **단계별 검증**: 각 단계마다 필요한 필드만 검증
- **클라이언트 사이드**: 실시간 검증, 에러 표시, 자동 스크롤
- **서버 사이드**: 모델 레벨 검증, 파일 형식/크기 제한

### URL 구조
- 주문 입력: `/orders/{naver_order_number}?step=1,2,3`
- 주문 인증: `/orders/{naver_order_number}/verify` (성함 입력/검증)
- 주문 완료: `/orders/{naver_order_number}/complete` (인증 후 접근)
- 관리자: `/admin`, `/admin/orders`, `/admin/settings`

## 주요 명령어

### 개발 환경
```bash
bin/dev                    # 개발 서버 실행 (Foreman)
npm run build:css:compile  # TailwindCSS 컴파일
rails test                 # 테스트 실행
rails db:migrate          # 마이그레이션
```

### 배포 관련
```bash
bin/kamal deploy          # 프로덕션 배포
bin/kamal rollback        # 이전 버전으로 롤백
bin/kamal app logs        # 실시간 로그 확인
bin/kamal ps             # 컨테이너 상태 확인
```

## 주요 검증 규칙

### 이미지 검증
- **지원 형식**: JPG, PNG만 허용
- **파일 크기**: 개당 최대 10MB
- **개수 제한**: 각 필드당 최대 5개
- **필수 사항**: main_images, optional_images 모두 필수

### 문자 수 제한
- **금속패**: 제목(15자), 성함(40자), 본문(150자)
- **아크릴패**: 상단문구(10자), 메시지(25자)

## 운영 및 배포

### 배포 환경
- **개발**: WSL2 Ubuntu + SQLite
- **프로덕션**: DigitalOcean + PostgreSQL

### 현재 배포 상태
**프로덕션 환경**: Kamal + DigitalOcean + Docker
- ✅ 도메인: https://www.giftrue.com
- ✅ 서버: DigitalOcean (159.223.53.175)
- ✅ 컨테이너: Docker 기반 배포
- ✅ 데이터베이스: PostgreSQL (프로덕션)
- ✅ SSL: Let's Encrypt 자동 갱신

**관리자 계정**:
- ID: `admin`
- Password: `password123`

### CSS 관리 및 개발 로직

**현재 정상 작동하는 CSS 시스템**:

#### 파일 구조
- **소스**: `app/assets/stylesheets/application.tailwind.css` (@import 형태)
- **컴파일된 파일**: `app/assets/builds/application.css` (실제 CSS 코드)
- **설정**: `tailwind.config.js` (content 경로 설정)
- **NPM 스크립트**: `package.json` (빌드 명령어)

#### 개발 환경에서 CSS 적용 과정
1. **개발 서버 실행**: `bin/dev` (Foreman 사용)
   - 자동으로 `npm run watch:css` 실행 (Procfile.dev)
   - TailwindCSS 워치 모드로 실시간 컴파일
2. **Rails 에셋 로딩**: `stylesheet_link_tag "application"`
   - `app/assets/builds/application.css` 파일 로드
   - 컴파일된 CSS 코드 적용

#### 수동 CSS 컴파일 방법
```bash
# 일회성 컴파일 (문제 해결용)
npm run build:css:compile

# 워치 모드 (개발용)
npm run watch:css
```

#### CSS 미적용 문제 예방 체크리스트
- [ ] `bin/dev` 실행 시 CSS 워치 프로세스 정상 동작 확인
- [ ] `app/assets/builds/application.css` 파일 존재 및 컴파일된 상태 확인
- [ ] 파일 첫 줄이 `*, ::before, ::after {` 형태인지 확인 (정상 컴파일됨)
- [ ] `@import "tailwindcss/base"` 형태라면 미컴파일 상태 (문제)
- [ ] 변경 후 브라우저 강력 새로고침 (Ctrl+Shift+R)

#### 긴급 복구 절차
1. **CSS 재컴파일**: `npm run build:css:compile`
2. **개발 서버 재시작**: `bin/dev` 중지 후 재실행
3. **브라우저 캐시 클리어**: 강력 새로고침 또는 캐시 삭제
4. **문제 지속 시**: `app/assets/builds/` 폴더 삭제 후 재컴파일

### 보안 및 모니터링
- **주문서 보안**: 완료된 주문은 성함 인증 후 접근 (1시간 세션)
- **이미지 업로드**: JPG/PNG, 10MB 제한, 최대 5개
- **모니터링**: 단계별 이탈률, CSS 로딩 상태, 주문 완료율

### 배포 가이드

**정상 배포 프로세스**:
```bash
bin/kamal deploy
```

**배포 실패 시 문제 해결 가이드**:

#### 1. SECRET_KEY_BASE 누락 에러
```
ArgumentError: Missing `secret_key_base` for 'production' environment
```

**해결 방법**:
1. **Secret key 생성**:
   ```bash
   ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
   ```

2. **deploy.yml에 환경변수 추가**:
   ```yaml
   env:
     secret:
       - SECRET_KEY_BASE  # 이 라인 추가
   ```

3. **.kamal/secrets 파일에 값 추가**:
   ```
   SECRET_KEY_BASE=[생성된_64자리_키]
   ```

#### 2. SSH 인증 실패 에러
```
ERROR (Errno::ENOTTY): Inappropriate ioctl for device
root@159.223.53.175's password:
```

**원인**: SSH key가 서버에 등록되지 않아 패스워드 인증을 시도하지만 터미널에서 입력받을 수 없음

**해결 방법**:
1. **DigitalOcean 웹 콘솔에서 서버 접속**
2. **SSH public key 등록**:
   ```bash
   # 로컬에서 public key 확인
   cat ~/.ssh/giftrue_key.pub
   
   # 서버 콘솔에서 실행
   mkdir -p ~/.ssh
   echo "ssh-rsa AAAAB3NzaC1yc2E..." >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   ```

3. **다시 배포 실행**: `bin/kamal deploy`

#### 3. 배포 성공 확인
- "First web container is healthy" 메시지 확인
- "Finished all in XX seconds" 메시지로 완료 확인
- https://giftrue.com 접속하여 정상 동작 확인

**수동 배포 프로세스** (Docker 미설치 시):
```bash
# 1. 코드 푸시
git add -A && git commit -m "변경사항" && git push origin main

# 2. 서버에서 수동 업데이트
ssh -i ~/.ssh/giftrue_key root@159.223.53.175 "cd /tmp && git clone https://github.com/go-dyc/giftrue-app.git"
# 필요 파일들 컨테이너에 복사

# 3. CSS가 변경된 경우
npm run build:css:compile
scp -i ~/.ssh/giftrue_key app/assets/builds/application.css root@159.223.53.175:/tmp/
ssh -i ~/.ssh/giftrue_key root@159.223.53.175 "docker cp /tmp/application.css giftrue-web-latest:/rails/public/assets/application.tailwind-0350fabe.css"
```

## Slack 알림 시스템

### 주문 완료 자동 알림 기능

**목적**: 주문이 완료되는 즉시 관리자에게 Slack 알림을 보내어 신속한 제작 대응 가능

#### 시스템 구성
- **Order 모델**: `after_update` 콜백으로 완료 시점 감지
- **SlackNotificationJob**: 백그라운드 작업으로 안정적인 알림 전송
- **SlackNotificationService**: 재사용 가능한 Slack API 연동 서비스

#### 설정 파일
```bash
# .env 파일
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

#### 자동 알림 발송 조건
- 주문의 `completed?` 메서드가 `true`를 반환할 때
- 모든 필수 정보 입력 완료 (성함, 사진, 기념패 스타일, 문구)
- 중복 알림 방지 로직 내장

#### 알림 내용
- 🎉 새 주문 접수 메시지
- 📋 주문번호, 고객명, 기념패 스타일
- 📁 첨부 파일 개수 (정면사진, 포즈사진)
- 📅 예상 배송일
- 🔗 관리자 페이지 직접 링크 (원클릭 주문 확인)

#### 코드 구조
```ruby
# app/models/order.rb
after_update :send_slack_notification_if_completed

# app/jobs/slack_notification_job.rb
class SlackNotificationJob < ApplicationJob
  def perform(order)
    SlackNotificationService.send_order_completion_notification(order)
  end
end

# app/services/slack_notification_service.rb
class SlackNotificationService
  def self.send_order_completion_notification(order)
    # Slack API 연동 로직
  end
end
```

#### 테스트 URL
- **간단 테스트**: `/orders/TEST-001/test_slack`
- **주문 알림 테스트**: `/orders/TEST-001/test_order_notification`

#### Slack 채널 설정
- **채널명**: #order-notifications
- **Webhook 앱**: Giftrue Order Notifications
- **알림 형태**: 리치 메시지 (Blocks API 사용)
- **보안**: 웹훅 URL은 환경변수로 관리 (.kamal/secrets 파일에서 제외)

#### 장점
- ⚡ **즉시성**: 주문 완료 즉시 알림
- 📱 **모바일 접근**: Slack 앱으로 어디서든 확인
- 🔗 **원클릭 접근**: 알림에서 바로 관리자 페이지로 이동
- 🛡️ **안정성**: Job 큐를 통한 백그라운드 처리
- 🔄 **확장성**: 다른 알림 (상태 변경, 배송 등)도 쉽게 추가 가능

## 주문 취소 관리 시스템 (2025-07-20 추가)

### 수동 취소 시스템
- **관리자 취소**: 관리자 페이지에서 주문 상태를 '주문취소'로 변경
- **취소 사유 입력**: 동적 폼으로 취소 사유 필수 입력
- **접근 차단**: 취소된 주문의 모든 고객 페이지 접근 자동 차단
- **안내 페이지**: 취소된 주문 접근 시 전용 안내 페이지 표시

### 네이버 커머스 API 연동
- **API 등록 완료**: 네이버 커머스 API 센터 가입 및 애플리케이션 등록
- **인증 설정**: Client ID/Secret 환경변수 설정 완료
- **API 서비스 개발**: NaverApiService 클래스 구현
- **테스트 시스템**: 관리자 API 테스트 페이지 `/admin/api_test`

**API 인증 방식** (2025-07-20 수정완료):
- ✅ **bcrypt 해싱**: 네이버 API 공식 스펙에 따른 올바른 시그니처 생성
- ✅ **의존성 추가**: `bcrypt` gem 활성화 및 설치 완료
- ✅ **인증 로직**: `client_id_timestamp` + bcrypt(client_secret) + Base64 인코딩

**현재 API 상태**: 인증 방식 수정 완료, IP 허용 리스트 설정 필요

### Order 모델 확장
```ruby
# 새로운 scope 추가
scope :cancelled, -> { where.not(cancelled_at: nil) }
scope :active, -> { where(cancelled_at: nil) }
scope :needs_polling, -> { active.where(last_api_polled_at: [nil, ...5.minutes.ago]) }

# 새로운 메서드
def cancelled? # 취소 여부 확인
def cancel!(reason = nil) # 수동 취소 처리
```

---

**문서 최종 업데이트**: 2025-07-21  
**개발 상태**: ✅ 프로덕션 배포 완료 + WSL 재설치 후 Git 저장소 복구 완료  
**주요 URL**: `/orders/{naver_order_number}` (고객용), `/admin` (관리자용), `/admin/api_test` (API 테스트)

**최신 개선사항** (2025-07-21):
- 🔄 **시스템 복구**: WSL 재설치로 인한 Git 저장소 손상 복구 완료
- 🐙 **Git 재설정**: GitHub 저장소 재초기화 및 전체 코드 업로드 완료
- 🔐 **인증 복구**: GitHub Personal Access Token 재설정 완료
- 📦 **Docker 환경**: WSL-Docker Desktop 연동 재설정 완료
- 🚀 **Kamal 설정**: `.kamal/secrets` 환경변수 재설정 완료
- ⚙️ **배포 준비**: 새로운 커밋 ID (`9a1ad51`)로 배포 준비 완료

**이전 개선사항** (2025-07-20):
- ❌ **주문 취소 시스템**: 수동 취소 관리 기능 완료
- 🔒 **접근 차단**: 취소된 주문 자동 차단 및 안내 페이지
- 🌐 **API 인증 개선**: 네이버 커머스 API bcrypt 시그니처 방식 수정 완료
- 🔐 **보안 강화**: bcrypt gem 추가, 공식 API 스펙 준수
- ⏰ **시간대 설정**: Asia/Seoul 시간대 적용

**현재 커밋**: `9a1ad51` (2025-07-21 WSL 재설치 후 복구)
**GitHub 저장소**: https://github.com/go-dyc/giftrue-app

**최신 환경 설정** (2025-07-22):
- 🔧 **권한 문제 해결**: bin/ 폴더 실행 권한 수정, .bashrc PATH 최적화
- 💎 **Rails 8.0.2**: WSL 내부 설치 완료 (Ruby 3.4.2와 호환)
- 🛠️ **개발환경 통합**: Ruby/Rails 모두 WSL 내부로 통일