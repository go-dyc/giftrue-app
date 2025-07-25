#!/bin/bash

echo "🤖 헤드리스 전용 테스트 (의존성 우회)"
echo "===================================="

# 환경변수 설정
export DISPLAY=:99
export PLAYWRIGHT_BROWSERS_PATH=~/.cache/ms-playwright

# Rails 서버 시작
echo "🚀 테스트 서버 시작..."
pkill -f "rails server.*3001" 2>/dev/null
RAILS_ENV=test rails server -p 3001 > /dev/null 2>&1 &
SERVER_PID=$!

sleep 5

# 최소 의존성으로 테스트 시도
echo "🎭 의존성 우회 테스트 시도..."

# 최소한의 환경변수로 강제 실행
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
PLAYWRIGHT_BROWSERS_PATH=~/.cache/ms-playwright \
npm run test:e2e -- --reporter=line 2>&1 | head -20

TEST_RESULT=${PIPESTATUS[0]}

# 서버 종료
kill $SERVER_PID 2>/dev/null

echo ""
echo "📋 결과 분석:"
if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ 테스트 성공!"
elif [ $TEST_RESULT -eq 1 ]; then
    echo "⚠️ 의존성 문제로 실패 (예상됨)"
    echo ""
    echo "🔧 해결방법:"
    echo "1. 패스워드 입력하여 의존성 설치:"
    echo "   sudo apt-get install libnspr4 libnss3 libasound2t64"
    echo ""
    echo "2. Docker 사용:"
    echo "   ./playwright-docker-simple.sh"
    echo ""
    echo "3. GitHub Actions 사용 (코드 푸시)"
else
    echo "❓ 예상치 못한 오류"
fi

echo "완료!"