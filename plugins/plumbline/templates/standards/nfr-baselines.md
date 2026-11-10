# NFR baselines

Company defaults for non-functional requirements. When a requirement document
is silent on one of these, the clarification step proposes the default below as
an assumption for you to confirm, instead of asking an open question.

Replace the example values with your own. Delete rows you have no default for.

| Quality | Default target | Measured by |
|---|---|---|
| Availability | 99.5% per month during business hours | Uptime monitoring |
| API response time | p95 under 500 ms at expected peak load | Load test in CI |
| Page load | Largest contentful paint under 2.5 s | Synthetic browser test |
| Recovery time | Service restored within 4 hours | Restore drill twice a year |
| Data loss limit | At most 1 hour of data | Backup schedule and restore drill |
| Security | No high or critical findings open at release | Dependency and static scans in CI |
| Test coverage | 80% line coverage on new code | Coverage report in CI |
| Accessibility | WCAG 2.1 AA for user-facing screens | Automated audit plus manual check |
| Audit log retention | 12 months | Retention policy check |
