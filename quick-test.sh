#!/bin/bash

echo "⚡ 빠른 Playwright 테스트"
echo "======================="

# 기존 서버 정리
pkill -f "rails server.*3001" 2>/dev/null
sleep 2

# CSS 컴파일
echo "🎨 CSS 컴파일..."
npm run build:css:compile > /dev/null 2>&1

# 테스트 DB 준비
echo "🗄️ 테스트 DB 준비..."
RAILS_ENV=test rails db:migrate > /dev/null 2>&1

# Rails 서버 시작 (백그라운드)
echo "🚀 테스트 서버 시작..."
RAILS_ENV=test rails server -p 3001 > /dev/null 2>&1 &
SERVER_PID=$!

# 서버 시작 대기
echo "⏳ 서버 준비 중..."
sleep 5

# 서버 응답 확인
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ 서버 정상 응답"
    
    # 간단한 수동 테스트
    echo "🧪 기본 테스트 실행..."
    
    # 관리자 로그인 페이지 테스트
    if curl -s http://localhost:3001/admin/login | grep -q "관리자"; then
        echo "✅ 관리자 로그인 페이지 OK"
    else
        echo "❌ 관리자 로그인 페이지 ERROR"
    fi
    
    # 주문 페이지 테스트
    if curl -s http://localhost:3001/orders/TEST-123 | grep -q "주문"; then
        echo "✅ 주문 페이지 OK"
    else
        echo "❌ 주문 페이지 ERROR"
    fi
    
    echo ""
    echo "🎉 기본 서버 테스트 완료!"
    echo ""
    echo "📋 Playwright 사용 가능한 방법들:"
    echo "1. 로컬 브라우저 테스트 (시스템 의존성 해결 후):"
    echo "   npm run test:e2e"
    echo ""
    echo "2. Docker로 완전 테스트:"
    echo "   docker run --rm --network host -v \$(pwd):/app -w /app"
    echo "   node:22-slim bash -c 'apt-get update && apt-get install -y curl &&"
    echo "   npx -y playwright@1.54.1 install --with-deps chromium &&"
    echo "   npm ci && npx playwright test --reporter=line'"
    echo ""
    echo "3. GitHub Actions (코드 푸시 시 자동 실행)"
    
else
    echo "❌ 서버 시작 실패"
fi

# 서버 종료
echo "🛑 서버 종료..."
kill $SERVER_PID 2>/dev/null

echo "완료!"