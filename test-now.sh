#!/bin/bash

echo "🎭 지금 바로 Playwright 테스트 실행"
echo "=================================="

# 1. 필요한 Docker 이미지 빌드
echo "📦 Playwright 테스트 환경 준비 중..."

# Dockerfile.simple 생성
cat > Dockerfile.simple << 'EOF'
FROM node:22-bookworm

# Playwright 의존성 설치
RUN npx -y playwright@1.54.1 install --with-deps chromium

WORKDIR /app

# 패키지 파일 복사
COPY package*.json ./

# 의존성 설치
RUN npm ci

# 앱 코드 복사
COPY . .

# CSS 컴파일
RUN npm run build:css:compile

# 테스트 실행 명령
CMD ["npm", "run", "test:e2e"]
EOF

# 2. 테스트용 Rails 서버 시작
echo "🚀 Rails 테스트 서버 시작..."
RAILS_ENV=test rails db:migrate 2>/dev/null
RAILS_env=test rails server -p 3001 -d

# 3. 서버 준비까지 대기
echo "⏳ 서버 준비 대기 중..."
sleep 8

# 4. Docker 이미지 빌드 및 테스트 실행
echo "🔨 Docker 이미지 빌드 및 테스트 실행..."
docker build -f Dockerfile.simple -t giftrue-playwright-test .

if [ $? -eq 0 ]; then
    echo "✅ Docker 이미지 빌드 성공!"
    echo "🎭 Playwright 테스트 실행 중..."
    
    docker run --rm \
        --network host \
        -e ADMIN_USERNAME=admin \
        -e ADMIN_PASSWORD=password123 \
        giftrue-playwright-test
    
    TEST_RESULT=$?
else
    echo "❌ Docker 이미지 빌드 실패"
    TEST_RESULT=1
fi

# 5. 정리
echo "🛑 테스트 서버 종료..."
pkill -f "rails server.*3001" 2>/dev/null

# 임시 파일 정리
rm -f Dockerfile.simple

if [ $TEST_RESULT -eq 0 ]; then
    echo "🎉 테스트 완료! 모든 테스트가 성공했습니다."
else
    echo "⚠️ 테스트에서 일부 실패가 있었습니다."
fi

exit $TEST_RESULT