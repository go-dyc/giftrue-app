# CSS 개발 및 문제 해결 가이드

## 현재 정상 작동하는 CSS 시스템

### 파일 구조
```
app/assets/stylesheets/application.tailwind.css  # 소스 파일 (@import 형태)
app/assets/builds/application.css                # 컴파일된 파일 (실제 CSS)
tailwind.config.js                               # TailwindCSS 설정
package.json                                     # NPM 스크립트
Procfile.dev                                     # 개발 서버 설정
```

### 정상 작동 개발 프로세스

#### 1. 개발 서버 시작
```bash
bin/dev
```
- Foreman이 `Procfile.dev`를 읽어 다음 프로세스 동시 실행:
  - `web`: Rails 서버 (`bin/rails server`)
  - `css`: TailwindCSS 워치 모드 (`npm run watch:css`)

#### 2. 자동 CSS 컴파일 프로세스
- `npm run watch:css` 명령어가 백그라운드에서 실행
- `app/assets/stylesheets/application.tailwind.css` 파일 변경 감지
- 자동으로 `app/assets/builds/application.css`로 컴파일

#### 3. Rails 에셋 로딩
- `app/views/layouts/application.html.erb`에서 `stylesheet_link_tag "application"` 실행
- 컴파일된 `app/assets/builds/application.css` 파일 로드

## CSS 상태 확인 방법

### 정상 컴파일된 상태 확인
```bash
head -3 app/assets/builds/application.css
```
**정상 출력 예시**:
```css
*, ::before, ::after {
  --tw-border-spacing-x: 0;
  --tw-border-spacing-y: 0;
```

### 미컴파일 상태 (문제)
```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";
```

## 문제 발생 시 해결 순서

### 1차: CSS 재컴파일
```bash
npm run build:css:compile
```

### 2차: 개발 서버 재시작
```bash
# 현재 bin/dev 프로세스 중지 (Ctrl+C)
bin/dev
```

### 3차: 브라우저 캐시 클리어
- **강력 새로고침**: `Ctrl + Shift + R` (Windows) / `Cmd + Shift + R` (Mac)
- **개발자 도구**: F12 → Network 탭 → "Disable cache" 체크 → 새로고침

### 4차: 빌드 폴더 초기화
```bash
rm -rf app/assets/builds/
npm run build:css:compile
```

## 예방 체크리스트

### 매번 개발 시작 전
- [ ] `bin/dev` 실행 후 CSS 워치 프로세스 정상 동작 확인
- [ ] 터미널에서 "Built app/assets/builds/application.css" 메시지 확인

### 스타일 변경 후
- [ ] `app/assets/builds/application.css` 파일이 자동 업데이트되는지 확인
- [ ] 브라우저에서 변경사항 즉시 반영되는지 확인
- [ ] 변경되지 않으면 강력 새로고침 실행

### 커밋 전
- [ ] `npm run build:css:compile` 한 번 더 실행
- [ ] 컴파일된 CSS 파일도 함께 커밋

## NPM 스크립트 정리

```json
{
  "scripts": {
    "build:css": "watch 모드 (사용 안 함)",
    "build:css:compile": "일회성 컴파일 (문제 해결용)",
    "watch:css": "워치 모드 (bin/dev에서 자동 실행)"
  }
}
```

## 자주 발생하는 문제와 해결책

### 문제 1: CSS가 적용되지 않음
**원인**: 컴파일되지 않은 @import 파일 로드
**해결**: `npm run build:css:compile` 실행

### 문제 2: 스타일 변경이 반영되지 않음
**원인**: 브라우저 캐시 또는 워치 프로세스 중단
**해결**: 강력 새로고침 또는 `bin/dev` 재시작

### 문제 3: bin/dev 실행 시 CSS 오류
**원인**: Node.js 또는 npm 의존성 문제
**해결**: `npm install` 재실행

### 문제 4: 프로덕션에서 CSS 미적용
**원인**: 배포 전 CSS 컴파일 누락
**해결**: Dockerfile에서 컴파일 과정 포함 확인

## 모니터링 포인트

### 개발 중 모니터링
- [ ] `bin/dev` 터미널에서 CSS 빌드 로그 확인
- [ ] 브라우저 개발자 도구에서 404 에러 없는지 확인
- [ ] 스타일 변경 시 즉시 반영되는지 확인

### 배포 후 모니터링
- [ ] CSS 파일 로딩 상태 확인
- [ ] 브라우저별 CSS 적용 상태 테스트
- [ ] 캐시 관련 이슈 모니터링

---

**가이드 작성일**: 2025-07-13  
**최종 검증**: ✅ 현재 시스템에서 정상 작동 확인