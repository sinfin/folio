# Seeding & Demo Data

The install generator places seed helpers under `lib/tasks/developer_tools.rake` and YAML files in `data/seed/`.

Useful tasks:

| Task | Description |
|------|-------------|
| `rake developer_tools:idp_seed_all` | Load sites, pages and menus from YAML |
| `rake folio:email_templates:idp_seed` | Import email templates from `data/email_templates*.yml` |
| `rake developer_tools:idp_seed_dummy_images` | Download Unsplash images for local development |

Run these after `rails db:seed` to bootstrap a new project. The tasks are safe to run multiple times and can be forced via `FORCE=1`.

---

[← Back to Overview](overview.md)
