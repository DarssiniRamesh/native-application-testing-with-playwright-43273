# .init scripts for native_application

This directory contains helper scripts used by the container:
- entrypoint.sh: Safe runtime entrypoint. Runs as root-only, never uses sudo, prints effective user, and executes the given command (or validation/help).
- entrypoint-override.sh: Used by Dockerfile ENTRYPOINT to bypass any external wrappers; it logs the effective user and chains to entrypoint.sh.
- validation.sh: Prints runtime invariants and confirms that sudo is not required; includes a NO-SUDO-NO-PWUSER marker for CI grepping.
- native_playwright_env.sh: Optional environment additions for local workflows. MUST NOT reference sudo or non-root users.

Guidelines:
- Do NOT introduce 'sudo', 'useradd', 'groupadd', 'chown -R <non-root>', or any 'pwuser' references.
- Keep scripts POSIX/Bash compatible and executable (chmod +x).
- Maintain the NO-SUDO-NO-PWUSER markers in logs for CI verification.
