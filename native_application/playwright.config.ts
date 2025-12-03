import { defineConfig, devices } from '@playwright/test';

// PUBLIC_INTERFACE
export default defineConfig({
  /** Playwright configuration for native_application container. */
  testDir: './tests',
  reporter: [['list']],
  use: {
    headless: process.env.PLAYWRIGHT_HEADLESS !== '0',
    baseURL: 'http://127.0.0.1:8080',
    trace: 'retain-on-failure',
    video: 'off',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
