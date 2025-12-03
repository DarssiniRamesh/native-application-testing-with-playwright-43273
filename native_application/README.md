# native_application container

This container provides a minimal Node.js + Playwright setup to run native-application tests.

Key notes:
- package.json exists with scripts:
  - npm run start -> serves current directory on port 8080 using http-server
  - npm test -> playwright test
- .init/native_playwright_env.sh sets safe environment variables and is sourced by the helper scripts.
- Dockerfile installs minimal OS deps and Playwright Chromium to a writable path.
- The image creates a non-root user 'pwuser' and runs the container under this user; no sudo is used or required.

Build examples (both contexts are supported):
  # From repository root:
  docker build -f native-application-testing-with-playwright-43273/native_application/Dockerfile -t native_application .
  # Or from container folder:
  cd native-application-testing-with-playwright-43273/native_application && docker build -t native_application .

Run example:
  docker run --rm -p 8080:8080 native_application
