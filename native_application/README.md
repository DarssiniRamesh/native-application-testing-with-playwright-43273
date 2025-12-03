# native_application container

This container provides a minimal Node.js + Playwright setup to run native-application tests.

Key notes:
- package.json exists with scripts:
  - npm run start -> serves current directory on port 8080 using http-server
  - npm test -> playwright test
- .init/native_playwright_env.sh sets safe environment variables and is sourced by the helper scripts (optional).
- Dockerfile installs minimal OS deps and Playwright Chromium to a writable path.
- The image creates an optional non-root user 'pwuser' (uid/gid 1001) for environments that need it. By default the container runs as root to avoid failures when external tooling injects 'sudo' or assumes root. No scripts call sudo.
- Entrypoint: /app/.init/entrypoint.sh which never invokes sudo and simply execs provided commands (or validation/help if none provided). It defensively adjusts permissions if running as root.

Build examples (both contexts are supported):
  # From repository root:
  docker build -f native-application-testing-with-playwright-43273/native_application/Dockerfile -t native_application .
  # Or from container folder:
  cd native-application-testing-with-playwright-43273/native_application && docker build -t native_application .

Run examples:
  # Interactive shell (default user: root for maximal compatibility):
  docker run --rm -it -p 8080:8080 native_application

  # Run as non-root pwuser (uid/gid 1001) if your CI requires:
  docker run --rm -it -p 8080:8080 --user 1001:1001 native_application

  # Run tests directly:
  docker run --rm native_application npm test

  # Serve static files:
  docker run --rm -p 8080:8080 native_application npm start

Notes:
- No scripts, Dockerfile commands, or examples use sudo.
- If an external CI tries to run sudo, either remove sudo usage or keep the default root user. Do not rely on a specific 'pwuser' at runtime—it's optional and may be selected via --user.
