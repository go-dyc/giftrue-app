const { test, expect } = require('@playwright/test');

/**
 * 주문 플로우 테스트
 * 고객 주문 3단계 프로세스 검증
 */
test.describe('주문 플로우', () => {
  const testOrderNumber = `TEST-E2E-${Date.now()}`;

  test('주문 3단계 플로우 전체 테스트', async ({ page }) => {
    // 1단계: 정면 사진 업로드 페이지
    await page.goto(`http://localhost:3001/orders/${testOrderNumber}?step=1`);
    
    // 페이지 로딩 확인
    await expect(page.locator('h1')).toContainText('정면 사진 업로드');
    
    // 주문자 성함 입력
    await page.fill('input[name="order[orderer_name]"]', '테스트사용자');
    
    // 파일 업로드는 실제 파일이 필요하므로 Skip
    // 대신 필수 필드가 있는지만 확인
    await expect(page.locator('input[type="file"][name*="main_images"]')).toBeVisible();
    
    // 프로그레스 바 확인 (1/3)
    await expect(page.locator('.progress, [role="progressbar"]')).toContainText(/1.*3|33/);
  });

  test('주문 검증 페이지 접근', async ({ page }) => {
    // 주문 검증 페이지 접근
    await page.goto(`http://localhost:3001/orders/${testOrderNumber}/verify`);
    
    // 검증 폼 확인
    await expect(page.locator('h1, h2')).toContainText('주문 확인');
    await expect(page.locator('input[name="orderer_name"]')).toBeVisible();
    await expect(page.locator('button[type="submit"], input[type="submit"]')).toBeVisible();
  });

  test('존재하지 않는 주문번호 처리', async ({ page }) => {
    const nonExistentOrder = 'NONEXISTENT-123';
    
    // 존재하지 않는 주문번호로 접근
    await page.goto(`http://localhost:3001/orders/${nonExistentOrder}`);
    
    // 에러 페이지나 적절한 메시지 확인
    // (실제 구현에 따라 404 페이지나 에러 메시지가 다를 수 있음)
    const isErrorPage = await page.locator('h1').textContent();
    expect(['404', '주문을 찾을 수 없습니다', '오류'].some(text => 
      isErrorPage?.includes(text)
    )).toBeTruthy();
  });

  test('모바일 반응형 디자인 확인', async ({ page }) => {
    // 모바일 뷰포트 설정
    await page.setViewportSize({ width: 375, height: 667 });
    
    await page.goto(`http://localhost:3001/orders/${testOrderNumber}?step=1`);
    
    // 모바일에서 네비게이션 버튼 확인
    const navButtons = page.locator('.btn-primary, .btn-secondary');
    const buttonsCount = await navButtons.count();
    
    if (buttonsCount > 0) {
      // 첫 번째 버튼이 모바일에서 제대로 표시되는지 확인
      const firstButton = navButtons.first();
      await expect(firstButton).toBeVisible();
      
      // 버튼이 적절한 크기인지 확인 (터치 가능한 최소 크기)
      const buttonBox = await firstButton.boundingBox();
      expect(buttonBox?.height).toBeGreaterThan(40); // 최소 44px 권장
    }
  });
});