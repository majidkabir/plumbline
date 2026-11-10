# Gap checklist

Areas that requirement documents often leave out. The quality check reports a
gap for each area that matters for this system and that no requirement covers.
Add your company's own recurring gaps here.

- Roles and permissions: who may do what; who administers roles.
- Authentication: how users and systems prove who they are; session rules.
- Audit: which actions are logged, with what detail, kept for how long.
- Error handling: what the actor sees and what the system does when a step fails.
- Validation: limits and formats of every input.
- Data retention and deletion: how long data is kept; how it is removed.
- Privacy and GDPR: personal data stored, legal basis, access and erasure requests.
- Migration: existing data or systems that must be carried over.
- Integrations: failure, retry and timeout behaviour for each external system.
- Concurrency: what happens when two actors change the same thing.
- Volumes: expected users, records, requests, growth.
- Availability and recovery: uptime target, backup, restore time, data loss limit.
- Performance: response time targets for the main flows.
- Observability: logs, metrics and alerts the operators need.
- Reporting and export: reports, exports, downstream consumers of the data.
- Notifications: who is told what, through which channel.
- Internationalisation: languages, time zones, currencies, formats.
- Accessibility: standard to meet.
- Operations: deployment, configuration, feature flags, support processes.
- Decommissioning: what this system replaces and when the old one is switched off.
