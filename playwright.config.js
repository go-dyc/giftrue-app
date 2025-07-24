// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Giftrue App - Playwright Configuration
 * Rails 애플리케이션을 위한 E2E 테스트 설정
 */
module.exports = defineConfig({
  testDir: './tests',
  /* 각 테스트 최대 실행 시간 */
  timeout: 30 * 1000,
  
  /* 각 테스트에서 expect 호출의 최대 대기 시간 */
  expect: {
    timeout: 5000
  },
  
  /* 테스트 실패 시 재시도 횟수 */
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  
  /* 리포터 설정 */
  reporter: 'html',
  
  /* 모든 프로젝트에서 공유되는 설정 */
  use: {
    /* 실패한 테스트의 스크린샷 수집 */
    screenshot: 'only-on-failure',
    
    /* 실패한 테스트의 비디오 수집 */
    video: 'retain-on-failure',
  },

  /* 프로젝트 별 구성 */
  projects: [
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Headless 모드 (UI 없이 실행)
        headless: true,
      },
    },
    
    {
      name: 'mobile-chrome',
      use: { 
        ...devices['Pixel 5'],
        headless: true,
      },
    },
  ],

  /* 로컬 개발 서버 설정 */
  webServer: {
    command: 'RAILS_ENV=test bin/rails server -p 3001',
    port: 3001,
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000, // 2분 대기
  },
});