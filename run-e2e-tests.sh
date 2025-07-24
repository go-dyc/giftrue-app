#!/bin/bash

echo "🚀 Giftrue E2E 테스트 실행 스크립트"
echo "=================================="

# 색깔 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Docker 실행 중인 컨테이너 정리
echo -e "${BLUE}기존 컨테이너 정리 중...${NC}"
docker-compose -f docker-compose.e2e.yml down --remove-orphans 2>/dev/null

# E2E 테스트 실행
echo -e "${GREEN}E2E 테스트 환경 시작...${NC}"
echo "이 과정은 몇 분 정도 소요될 수 있습니다."
echo ""

# Docker Compose로 전체 환경 실행
docker-compose -f docker-compose.e2e.yml up --build --abort-on-container-exit

# 결과 확인
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ E2E 테스트 완료!${NC}"
else
    echo -e "${RED}❌ E2E 테스트 실패${NC}"
    echo -e "${YELLOW}로그를 확인해보세요.${NC}"
fi

# 정리
echo -e "${BLUE}컨테이너 정리 중...${NC}"
docker-compose -f docker-compose.e2e.yml down --remove-orphans

echo "테스트 완료!"