---
description: Security rules enforced in all sessions. These are non-negotiable and apply regardless of project type, client, or phase.
globs: *
---

# Security Rules

## Secrets and Credentials

- Never commit secrets, credentials, API keys, or tokens to version control
- Never hardcode secrets in source code, configuration files, or infrastructure definitions
- Use environment variables or a secrets manager (e.g., Vault, GCP Secret Manager, AWS Secrets Manager) for all sensitive values
- If a secret is accidentally committed, treat it as compromised: rotate immediately, do not just delete from history
- Add secret patterns to `.gitignore` and pre-commit hooks (e.g., `detect-secrets`, `gitleaks`)

## Git Safety

- Never use `--no-verify` on git commits - pre-commit hooks exist for a reason
- Never force push (`--force`, `-f`) to `main` or `master` branches
- Never rewrite published history on shared branches

## Input Validation

- Validate all user inputs at system boundaries (API endpoints, CLI arguments, file uploads)
- Use parameterized queries for all database operations - never use string interpolation or concatenation to build SQL
- Sanitize inputs before rendering in HTML to prevent XSS
- Validate and sanitize file paths to prevent directory traversal attacks
- Reject unexpected input types and sizes early

## Authentication and Authorization

- Never store passwords in plaintext - use bcrypt, argon2, or scrypt with appropriate work factors
- Never implement custom cryptography - use established libraries
- Use short-lived tokens with refresh mechanisms
- Apply principle of least privilege to all service accounts and IAM roles
- Validate authorization on every request, not just at login

## OWASP Top 10 Compliance

Follow mitigations for the OWASP Top 10:
- **Broken Access Control**: Enforce server-side access checks, deny by default
- **Cryptographic Failures**: Use TLS 1.2+, encrypt sensitive data at rest, never log secrets
- **Injection**: Parameterized queries, input validation, output encoding
- **Insecure Design**: Threat model before building, use secure design patterns
- **Security Misconfiguration**: No default credentials, disable unnecessary features, keep systems patched
- **Vulnerable Components**: Scan dependencies for known CVEs, update regularly
- **Identification/Auth Failures**: MFA where possible, rate limit auth endpoints, no default passwords
- **Data Integrity Failures**: Verify software integrity (checksums, signatures), validate CI/CD pipeline integrity
- **Logging/Monitoring Failures**: Log security events, alert on anomalies, retain logs per policy
- **SSRF**: Validate and sanitize all URLs, use allowlists for outbound requests

## Dependency Security

- Scan dependencies for known vulnerabilities before adding them (e.g., `pip-audit`, `npm audit`, `snyk`)
- Pin dependency versions in production (no floating ranges)
- Review transitive dependencies, not just direct ones
- Remove unused dependencies - they expand the attack surface

## Logging and Data Protection

- Never log sensitive data: PII, credentials, tokens, session IDs, credit card numbers
- Never log full request/response bodies that may contain sensitive data
- Use structured logging with explicit field selection
- Mask or redact sensitive fields in log output
- Set appropriate log retention periods per compliance requirements

## Encryption

- Use TLS 1.2+ for all data in transit
- Encrypt sensitive data at rest using platform-native encryption (e.g., GCP CMEK, AWS KMS)
- Use strong cipher suites and disable deprecated ones
- Rotate encryption keys on a defined schedule

## Infrastructure Security

- No public-facing resources without explicit justification and approval
- Use private endpoints for database and service-to-service communication
- Apply network segmentation (separate data, application, and management planes)
- Enable audit logging on all cloud resources
- Use infrastructure as code for security configuration (no manual console changes)
