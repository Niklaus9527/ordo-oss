# Security Policy

## Reporting a Vulnerability
If you discover a security vulnerability, please report it privately.

- Do NOT open a public issue with exploit details.
- Send a report to the maintainers via the contact method described in `GOVERNANCE.md`.

We will acknowledge your report and work on a fix as soon as possible.

## Supported Versions
Security fixes are applied to the latest minor release line.

## Secrets & Keys
- Never commit API keys, tokens, or private endpoints.
- Use `.env` and environment variables for local setup.
- Examples default to mock providers to avoid external dependencies.