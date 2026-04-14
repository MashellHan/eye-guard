# EyeGuard Agent Collaboration Protocol

## Agents

| Role | Responsibility | Artifacts |
|------|---------------|-----------|
| **PM** | Competitive research, feature specs, UX design | `pm/specs/`, `pm/research/`, `pm/ux/` |
| **Lead** | Architecture design, code review, acceptance | `lead/architecture/`, `lead/reviews/`, `lead/acceptance/` |
| **Dev** | Code implementation, git commits, push | `dev/notes/` |
| **Tester** | Test cases, bug reports, QA | `tester/reports/`, `tester/bugs/` |

## Workflow per Iteration (~30 min)

```
Phase 1: PM writes/updates spec → Lead reviews spec
Phase 2: Dev implements based on approved spec
Phase 3: Lead reviews code → Tester tests
Phase 4: Feedback → Dev fixes → next iteration
```

## Handoff Protocol

Each handoff document goes to `.eye-guard/handoffs/` with naming:
```
{version}-{from}-to-{to}-{timestamp}.md
```

Example: `v0.1-pm-to-lead-20260414-2200.md`

## Document Versioning

All specs, reviews, reports use version prefix: `v0.1-`, `v0.2-`, etc.

## Acceptance Criteria

- PM + Lead both approve for 3 consecutive hours → auto-acceptance
- Each version must pass Tester's test report before moving on
- Critical bugs block version advancement

## Iteration Log

Track iterations in `.eye-guard/handoffs/iteration-log.md`
