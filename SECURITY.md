# Magic Lane Open Source Security Policy

Magic Lane takes the security of our software and services seriously, including open source repositories maintained under our GitHub organization: https://github.com/magiclane.

This document explains how to report security vulnerabilities **privately** and what information to include so we can triage quickly.

## Reporting Security Vulnerabilities

If you believe you have found a security vulnerability, please report it **privately** by email to:

**security@magiclane.com**

Suggested subject line: **`[SECURITY] <repo-name>: <short summary>`**

## Information to Include

Please include the requested information listed below (as much as you can provide) to help us better understand the nature and scope of the possible issue:

- The repository name or URL
- Type of issue (buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of the source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any particular configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

This information will help us triage your report more quickly.

## Please Do Not

To protect users and enable coordinated remediation:

- Do **not** open a public GitHub issue, discussion, or pull request for security vulnerabilities
- Do **not** publicly disclose details (blog posts, social media, mailing lists) before we coordinate disclosure
- Do **not** access, modify, or exfiltrate data that does not belong to you
- Do **not** perform testing that could degrade availability (e.g., denial-of-service)

If you believe you may have accessed sensitive data unintentionally, stop immediately and mention it in your report.

## Coordinated Disclosure

We support coordinated vulnerability disclosure and ask that you:

- Report vulnerabilities privately
- Avoid exploitation beyond what is necessary to demonstrate the issue
- Allow reasonable time for investigation and remediation before public disclosure

## Preferred Language

For efficient communication, we prefer reports in **English**.

## Questions (Non-Vulnerability)

For general questions not involving vulnerability reports, please use the repository’s normal support channels or visit:

https://developer.magiclane.com
