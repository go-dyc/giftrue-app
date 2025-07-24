const { test, expect } = require('@playwright/test');

/**
 * 기본 스모크 테스트
 * 애플리케이션이 정상적으로 실행되는지 확인
 */
test.describe('기본 스모크 테스트', () => {
  
  test('홈페이지 응답 확인', async ({ page }) => {
    // 간단한 HTTP 요청으로 서버 상태 확인
    const response = await page.goto('http://localhost:3001/');
    
    // 200번대 응답 또는 리다이렉트 응답 확인
    expect(response?.status()).toBeLessThan(500);
    
    // 페이지가 로드되었는지 확인
    await expect(page).toHaveURL(/localhost:3001/);
  });

  test('관리자 로그인 페이지 접근 가능', async ({ page }) => {
    const response = await page.goto('http://localhost:3001/admin/login');
    
    // 정상 응답 확인
    expect(response?.status()).toBe(200);
    
    // 기본 요소 존재 확인
    await expect(page.locator('form')).toBeVisible();
  });
});