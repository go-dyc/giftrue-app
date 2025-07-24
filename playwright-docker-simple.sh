#!/bin/bash

echo "🎭 Docker로 Playwright 테스트 (간단 버전)"
echo "========================================"

# 서버 정리
pkill -f "rails server.*3001" 2>/dev/null

# Rails 서버 시작
echo "🚀 Rails 서버 시작..."
RAILS_ENV=test rails server -p 3001 > /dev/null 2>&1 &
SERVER_PID=$!

sleep 5

# Docker로 Playwright 실행 (더 간단한 방법)
echo "🎭 Playwright 테스트 실행..."

docker run --rm \
  --network host \
  -v $(pwd):/workspace \
  -w /workspace \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=password123 \
  node:22-bullseye-slim \
  bash -c "
    echo '📦 의존성 설치 중...' &&
    apt-get update -qq &&
    apt-get install -y -qq curl &&
    npm ci --silent &&
    echo '🎭 Playwright 설치 중...' &&
    npx -y playwright@1.54.1 install --with-deps chromium &&
    echo '🧪 테스트 실행 중...' &&
    npx playwright test --reporter=line --project=chromium tests/basic-smoke.spec.js
  "

TEST_RESULT=$?

# 서버 종료
kill $SERVER_PID 2>/dev/null

if [ $TEST_RESULT -eq 0 ]; then
    echo "🎉 테스트 성공!"
else
    echo "⚠️ 테스트 실패 또는 부분 실패"
fi

echo "완료!"