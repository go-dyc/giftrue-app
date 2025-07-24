#!/bin/bash

echo "🎭 간단한 Playwright 테스트 실행"
echo "================================"

# 필요한 패키지 설치 확인
if ! command -v npm &> /dev/null; then
    echo "❌ npm이 설치되어 있지 않습니다."
    exit 1
fi

# node_modules 확인
if [ ! -d "node_modules/@playwright" ]; then
    echo "📦 Playwright 패키지 설치 중..."
    npm install
fi

# CSS 컴파일
echo "🎨 CSS 컴파일 중..."
npm run build:css:compile

# Rails 테스트 DB 준비
echo "🗄️ 테스트 데이터베이스 준비 중..."
RAILS_ENV=test rails db:migrate 2>/dev/null

# 테스트 서버 백그라운드 시작
echo "🚀 테스트 서버 시작 중..."
RAILS_ENV=test rails server -p 3001 -d

# 서버 시작까지 대기
sleep 5

# Docker로 Playwright만 실행
echo "🎭 Playwright 테스트 실행 중..."
docker run --rm \
  --network host \
  -v $(pwd):/app \
  -w /app \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=password123 \
  playwright:v1.54.1 \
  bash -c "npm ci && npx playwright test --reporter=line" || \
docker run --rm \
  --network host \
  -v $(pwd):/app \
  -w /app \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=password123 \
  mcr.microsoft.com/playwright:v1.54.1-jammy \
  bash -c "npm ci && npx playwright test --reporter=line"

# 결과 저장
TEST_RESULT=$?

# 테스트 서버 종료
echo "🛑 테스트 서버 종료 중..."
pkill -f "rails server.*3001" 2>/dev/null

if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ 테스트 성공!"
else
    echo "❌ 테스트 실패 (종료 코드: $TEST_RESULT)"
fi

exit $TEST_RESULT