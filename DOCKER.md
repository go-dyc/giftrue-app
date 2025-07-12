# Docker 배포 가이드

## 개발 환경

### 로컬 개발 (권장)
```bash
# 기본 개발 환경
bin/dev
```

### Docker를 사용한 개발
```bash
# 개발용 Docker Compose (시간이 오래 걸림)
docker-compose -f docker-compose.dev.yml up

# 또는 간단한 개발용 이미지 빌드
docker build -f Dockerfile.simple -t giftrue:dev .
docker run -p 3000:3000 -v $(pwd):/rails giftrue:dev
```

## 운영 환경

### 운영용 이미지 빌드
```bash
# 운영용 이미지 빌드
docker build -t giftrue:prod .

# 운영용 이미지 실행
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=your_production_database_url \
  --name giftrue-prod \
  giftrue:prod
```

### PostgreSQL과 함께 운영
```bash
# PostgreSQL과 함께 실행
docker-compose up -d
```

## 주요 파일

- `Dockerfile`: 운영용 멀티스테이지 빌드
- `Dockerfile.simple`: 개발용 단순 빌드
- `docker-compose.yml`: PostgreSQL과 함께 운영
- `docker-compose.dev.yml`: 개발용 환경

## 환경 변수

- `RAILS_MASTER_KEY`: Rails 마스터 키 (필수)
- `DATABASE_URL`: 데이터베이스 연결 정보
- `RAILS_ENV`: Rails 환경 (production/development)

## 트러블슈팅

1. **빌드 시간이 오래 걸림**: Ruby gems와 Node.js 패키지 설치 때문
2. **권한 오류**: 파일 권한을 확인하고 `chown -R rails:rails` 사용
3. **데이터베이스 연결 오류**: DATABASE_URL 환경변수 확인