# Upgrade & Migration

This chapter aggregates the most relevant upgrade paths and migrations for the Folio Rails Engine. Content is derived from the original wiki articles and verified against the current codebase.

---

## Checklist Before You Start

1. Commit and push all pending changes.
2. Run the test suite and ensure it is green.
3. Create a fresh backup of the database and uploaded files.
4. Read the release notes for every Folio version you are jumping over.

---

## Generator-Based Approach

For many upgrades the safest path is to **re-run the relevant Folio generator** in a throw-away branch, compare the generated files with your project, and cherry-pick differences.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Troubleshooting](troubleshooting.md)
- [Next: Extending & Customization →](extending.md)

---

*Always read the changelog and test thoroughly before deploying upgrades to production.* 
