# SOP: Client Data Handling

Working with client data safely when using Claude Code and the cc-framework.

---

## Data Classification Levels

| Level | Description | Handling Rules |
|-------|-------------|----------------|
| **Public** | Publicly available information | No restrictions |
| **Internal** | Internal business data, not sensitive | Do not share externally. Can use in dev/test environments. |
| **Confidential** | Business-sensitive data, trade secrets | Encrypted at rest and in transit. Access logged. No use in non-prod without masking. |
| **Restricted** | PII, PHI, PCI, regulated data | Full encryption (CMEK). Anonymize/mask for dev/test. Access requires justification. Audit all access. |

---

## Core Rules

### 1. Never Commit Client Data to Version Control

- No sample data files in Git (even "small" samples)
- No database dumps, CSV exports, or JSON fixtures with real data
- No screenshots containing client data
- Use `.gitignore` patterns: `*.csv`, `*.parquet`, `data/`, `exports/`
- Use synthetic or anonymized data for test fixtures

### 2. Anonymization and Masking for Development

When you need realistic data for development or testing:

- **Faker library** for generating synthetic data matching expected schemas
- **Hash-based masking** for maintaining referential integrity (same input = same masked output)
- **Range preservation** for numeric fields (maintain distribution without real values)
- **Date shifting** for temporal data (shift all dates by a consistent random offset)

Never copy production data to development environments without masking.

### 3. PII Handling

PII categories requiring special handling:
- Names, email addresses, phone numbers
- Social Security Numbers, government IDs
- Financial account numbers, credit card numbers
- Health information (PHI)
- Biometric data
- Location data (precise coordinates)

Rules:
- PII columns must be tagged in metadata catalogs
- PII must not appear in log files, error messages, or exception traces
- PII must not be sent to Claude Code's context unless absolutely necessary for the task
- When PII must be processed, use the minimum necessary
- Apply column-level encryption or tokenization for Restricted PII

### 4. Data Retention and Cleanup

- Delete local data copies after the task is complete
- Do not store client data on personal devices beyond the work session
- Follow client-specific retention policies (documented in `.claude/rules/client-ea.md`)
- Clean up temporary files, notebooks, and scratch work

### 5. Incident Reporting for Data Exposure

If client data is accidentally exposed (committed to Git, sent to wrong channel, etc.):

1. **Immediately** notify the engagement lead
2. **Do not** try to cover it up — transparency is critical
3. **Assess** the scope: what data, what classification level, who had access
4. **Remediate**: remove from Git history (BFG Repo Cleaner), revoke access, rotate credentials if needed
5. **Report** per client's incident response procedure
6. **Document** in the engagement's incident log

---

## MCP Server Data Access

### What MCP Servers Can See

- **Jira MCP**: Issue titles, descriptions, comments, attachments
- **Confluence MCP**: Page content, attachments, space metadata
- **Cloud Platform MCP**: Resource metadata, query results, bucket contents

### Boundaries

- MCP servers respect IAM permissions — they can only access what your credentials allow
- Do not grant MCP servers broader access than needed for the task
- Use read-only credentials where possible (especially for production data)
- Review MCP server audit logs periodically

### Claude Code Context

- Data read by Claude Code enters the conversation context
- Conversation context is subject to Anthropic's data handling policies
- For Restricted data, minimize what enters the context
- Use targeted queries (specific columns, filtered rows) rather than broad reads

---

## Working with Claude Code Enterprise

Claude Code Enterprise provides additional data protections:

- **180-day audit logs**: All tool uses are logged
- **Compliance API**: Query audit data programmatically
- **Managed settings**: Organization can enforce data access policies
- **SSO**: Enterprise identity management

These features help meet compliance requirements (SOC 2, HIPAA, GDPR) but do not replace the need for careful data handling practices.
