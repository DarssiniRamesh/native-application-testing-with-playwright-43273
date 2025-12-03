import { test, expect } from '@playwright/test';

// PUBLIC_INTERFACE
test('container smoke: http server serves directory index', async ({ page }) => {
  /** This smoke test verifies the container's http-server is running and reachable. */
  await page.goto('http://127.0.0.1:8080');
  // We don't know what files will exist; assert that some basic text exists (directory index)
  const bodyText = await page.locator('body').innerText();
  expect(bodyText.length).toBeGreaterThan(0);
});
