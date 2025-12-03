# native_application container

This container provides a minimal Node.js + Playwright setup to run native-application tests.

Key notes:
- package.json exists with scripts:
  - npm run start -> serves current directory on port 8080 using http-server
  - npm test -> playwright test
- .init/native_playwright_env.sh sets safe environment variables and is sourced by the helper scripts (optional).
- Dockerfile installs minimal OS deps and Playwright Chromium to a writable path.
- The image runs as root exclusively. No scripts call sudo, and there is no dependency on any additional user.
- Entrypoint: /app/.init/entrypoint.sh which never invokes sudo and simply execs provided commands (or validation/help if none provided).

Build examples (both contexts are supported):
  # From repository root:
  docker build -f native-application-testing-with-playwright-43273/native_application/Dockerfile -t native_application .
  # Or from container folder:
  cd native-application-testing-with-playwright-43273/native_application && docker build -t native_application .

Run examples:
  # Interactive shell (default user: root for maximal compatibility):
  docker run --rm -it -p 8080:8080 native_application



  # Run tests directly:
  docker run --rm native_application npm test

  # Serve static files:
  docker run --rm -p 8080:8080 native_application npm start

Notes:
- No scripts, Dockerfile commands, or examples use sudo.
- If an external CI tries to run sudo, either remove sudo usage or keep the default root user. Do not rely on a specific 'pwuser' at runtime—it's optional and may be selected via --user.
