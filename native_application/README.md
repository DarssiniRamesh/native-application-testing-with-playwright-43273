# native_application container

This container provides a minimal Node.js + Playwright setup to run native-application tests.

Key notes:
- package.json exists with scripts:
  - npm run start -> serves current directory on port 8080 using http-server
  - npm test -> playwright test
- .init/native_playwright_env.sh sets safe environment variables and is sourced by the helper scripts.
- Dockerfile installs minimal OS deps and Playwright Chromium to a writable path.

Build example:
  docker build -t native_application .

Run example:
  docker run --rm -p 8080:8080 native_application
