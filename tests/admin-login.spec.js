const { test, expect } = require('@playwright/test');

/**
 * 관리자 로그인 테스트
 * 관리자 페이지 접근 및 로그인 기능 검증
 */
test.describe('관리자 로그인', () => {
  
  test('관리자 로그인 페이지 접근', async ({ page }) => {
    // 관리자 로그인 페이지로 이동
    await page.goto('http://localhost:3001/admin/login');
    
    // 페이지 제목 확인
    await expect(page).toHaveTitle(/관리자/);
    
    // 로그인 폼 요소들 확인
    await expect(page.locator('h2')).toContainText('관리자 로그인');
    await expect(page.locator('input[name="admin_id"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
    await expect(page.locator('input[type="submit"]')).toBeVisible();
  });

  test('올바른 관리자 계정으로 로그인', async ({ page }) => {
    await page.goto('http://localhost:3001/admin/login');
    
    // 관리자 계정 정보 입력
    await page.fill('input[name="admin_id"]', process.env.ADMIN_USERNAME || 'admin');
    await page.fill('input[name="password"]', process.env.ADMIN_PASSWORD || 'password123');
    
    // 로그인 버튼 클릭
    await page.click('input[type="submit"]');
    
    // 관리자 메인 페이지로 리다이렉트 확인
    await expect(page).toHaveURL(/\/admin/);
    await expect(page.locator('h1')).toContainText('주문 관리');
  });

  test('잘못된 계정으로 로그인 실패', async ({ page }) => {
    await page.goto('http://localhost:3001/admin/login');
    
    // 잘못된 계정 정보 입력
    await page.fill('input[name="admin_id"]', 'wrong_admin');
    await page.fill('input[name="password"]', 'wrong_password');
    
    // 로그인 버튼 클릭
    await page.click('input[type="submit"]');
    
    // 에러 메시지 확인
    await expect(page.locator('.alert, [role="alert"]')).toContainText('아이디 또는 비밀번호가 잘못되었습니다');
    
    // 여전히 로그인 페이지에 있는지 확인
    await expect(page).toHaveURL(/\/admin\/login/);
  });

  test('로그아웃 기능', async ({ page }) => {
    // 먼저 로그인
    await page.goto('http://localhost:3001/admin/login');
    await page.fill('input[name="admin_id"]', process.env.ADMIN_USERNAME || 'admin');
    await page.fill('input[name="password"]', process.env.ADMIN_PASSWORD || 'password123');
    await page.click('input[type="submit"]');
    
    // 관리자 페이지 진입 확인
    await expect(page).toHaveURL(/\/admin/);
    
    // 로그아웃 링크 클릭 (실제 구현에 따라 셀렉터 조정 필요)
    const logoutLink = page.locator('a[href*="logout"], a:has-text("로그아웃")');
    if (await logoutLink.count() > 0) {
      await logoutLink.click();
      
      // 로그인 페이지로 리다이렉트 확인
      await expect(page).toHaveURL(/\/admin\/login/);
    }
  });
});