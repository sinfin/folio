# Folio – Ruby on Rails CMS Engine

Folio is an open-source engine that turns any Rails application into a modern, multi-site CMS with a beautiful admin console, modular content blocks, and a rich set of generators.

*Build pages from reusable blocks. Scaffold admin UIs in seconds. Keep full control of the code.*

---

## Why Folio?

• **Productive** – Generators for pages, components, mailers, blog, search, …  
• **Flexible** – Compose pages from CMS blocks (Atoms) rendered by ViewComponent.  
• **Modern** – Console UI built with Stimulus & ViewComponent, ready for Turbo.  
• **Ruby First** – 100 % Ruby / Slim / SASS, no proprietary DSLs.  
• **Upgrade-safe** – Override via `app/overrides/`, keep your customisations isolated.

---

## Quick Installation

```bash
bundle add folio dragonfly_libvips view_component
rails generate folio:install
rails db:migrate
rails server
```
Open <http://localhost:3000/console> and log in with the credentials printed by the installer seed.

---

## Documentation

Full English documentation lives in the `docs/` folder:

| Topic | File |
|-------|------|
| Overview | [docs/overview.md](docs/overview.md) |
| Architecture | [docs/architecture.md](docs/architecture.md) |
| Components | [docs/components.md](docs/components.md) |
| CMS Blocks (Atoms) | [docs/atoms.md](docs/atoms.md) |
| Admin Console | [docs/admin.md](docs/admin.md) |
| Files & Media | [docs/files.md](docs/files.md) |
| Forms | [docs/forms.md](docs/forms.md) |
| Emails & Templates | [docs/emails.md](docs/emails.md) |
| Configuration | [docs/configuration.md](docs/configuration.md) |
| Testing | [docs/testing.md](docs/testing.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Upgrade & Migration | [docs/upgrade.md](docs/upgrade.md) |
| Extending & Customisation | [docs/extending.md](docs/extending.md) |
| FAQ | [docs/faq.md](docs/faq.md) |

Start with the [Overview](docs/overview.md) and follow the *Quick Start* guide.

---

## Contributing

1. Fork the repo and create your branch (`git checkout -b feature/my-thing`).
2. Run the dummy app for development: `bundle exec rails app:folio:prepare_dummy_app`.
3. Commit your changes (`git commit -am 'Add new thing'`).
4. Push the branch (`git push origin feature/my-thing`).
5. Open a Pull Request.

See `docs/testing.md` for the test setup.

---

## License

Folio is released under the MIT License – see `LICENSE` for details.
