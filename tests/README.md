# Giftrue E2E Tests

Playwright를 사용한 종단간 테스트 모음입니다.

## 📋 테스트 목록

### `basic-smoke.spec.js`
- 기본 서버 응답 확인
- 관리자 로그인 페이지 접근 테스트

### `admin-login.spec.js`
- 관리자 로그인/로그아웃 기능
- 인증 실패 처리
- 권한 확인

### `order-flow.spec.js`
- 고객 주문 3단계 플로우
- 주문 검증 프로세스
- 모바일 반응형 테스트

## 🚀 실행 방법

### 로컬 개발 환경

```bash
# 모든 테스트 실행
npm run test:e2e

# UI 모드로 실행 (브라우저에서 테스트 확인)
npm run test:e2e:ui

# 디버그 모드로 실행
npm run test:e2e:debug

# 특정 테스트만 실행
npm run test:e2e -- tests/basic-smoke.spec.js

# 테스트 리포트 보기
npm run test:e2e:report
```

### 필수 조건

1. **시스템 의존성 설치** (Ubuntu/WSL):
   ```bash
   sudo apt-get install libnspr4 libnss3 libasound2t64
   # 또는
   sudo npx playwright install-deps
   ```

2. **Rails 서버 실행** (테스트 환경):
   ```bash
   RAILS_ENV=test rails db:migrate
   RAILS_ENV=test rails server -p 3001
   ```

3. **환경변수 설정**:
   ```bash
   export ADMIN_USERNAME=admin
   export ADMIN_PASSWORD=password123
   ```

### Docker에서 실행

```bash
# Dockerfile.playwright 생성 후
docker build -f Dockerfile.playwright -t giftrue-e2e .
docker run --rm giftrue-e2e
```

## 🔧 설정

### `playwright.config.js`
- 테스트 타임아웃: 30초
- 재시도 횟수: CI에서 2회, 로컬에서 0회
- 브라우저: Chrome (데스크톱), Chrome (모바일)
- 서버: localhost:3001 (테스트 환경)

### CI/CD 통합
- GitHub Actions: `.github/workflows/playwright.yml`
- 자동 의존성 설치
- PostgreSQL 데이터베이스 서비스
- 테스트 결과 아티팩트 저장

## 📊 테스트 커버리지

현재 테스트 커버리지:
- ✅ 관리자 로그인/인증
- ✅ 기본 페이지 접근성
- ✅ 모바일 반응형 UI
- 🚧 주문 플로우 (파일 업로드 제외)
- 🚧 AI 문구 생성 기능
- 🚧 이미지 업로드 프로세스

## 🐛 알려진 문제

1. **시스템 의존성**: WSL/Ubuntu에서 브라우저 실행을 위한 추가 패키지 필요
2. **파일 업로드**: 실제 파일 업로드 테스트는 별도 설정 필요
3. **데이터베이스**: 테스트 간 데이터 격리 개선 필요

## 📝 테스트 작성 가이드

새로운 테스트 작성 시 고려사항:

1. **테스트 격리**: 각 테스트는 독립적으로 실행 가능해야 함
2. **대기 조건**: `await expect()` 사용으로 적절한 대기
3. **모바일 지원**: 반응형 디자인 테스트 포함
4. **에러 처리**: 실패 케이스도 함께 테스트
5. **성능**: 불필요한 대기 시간 최소화

예시:
```javascript
test('새로운 기능 테스트', async ({ page }) => {
  await page.goto('/feature');
  await expect(page.locator('h1')).toContainText('Feature');
  
  // 모바일 테스트
  await page.setViewportSize({ width: 375, height: 667 });
  await expect(page.locator('.mobile-nav')).toBeVisible();
});
```