# Folio Rails Engine – Documentation Overview

Welcome to the documentation for the **Folio Rails Engine**. This project provides a modular, extensible CMS engine for Ruby on Rails applications, featuring a modern admin interface, flexible content modeling, and a robust component system.

> **Note:** This documentation is a living document. Chapters will be expanded and refined as the migration from legacy sources progresses.

---

## Table of Contents

- [Architecture](architecture.md) — Engine structure, main models, data flows, diagrams
- [Components](components.md) — ViewComponents, UI structure, BEM, Stimulus, React
- [Atoms](atoms.md) — Content atoms, types, usage, extension
- [Admin Console](admin.md) — Admin UI, scaffolding, user roles, multi-site
- [Files & Media](files.md) — File handling, media, metadata, placements
- [Forms](forms.md) — Form building, validation, custom inputs
- [Emails & Templates](emails.md) — Email templates, newsletters
- [Configuration](configuration.md) — Engine setup, options, localization
- [Testing](testing.md) — Testing strategies, helpers, best practices
- [Troubleshooting](troubleshooting.md) — Common issues and solutions
- [Upgrade & Migration](upgrade.md) — Upgrading projects, migration guides
- [Extending & Customization](extending.md) — Generators, overrides, custom code
- [FAQ](faq.md) — Frequently asked questions

---

## Chapter Summaries

**Architecture:**
- Overview of the engine's structure, key models, and data flows. Includes Mermaid diagrams for visual reference.

**Components:**
- How to use and build UI components with ViewComponent, BEM, and Stimulus. Covers React integration and best practices.

**Atoms:**
- Working with content atoms, defining new types, and extending atom functionality.

**Admin Console:**
- Using and customizing the admin interface, scaffolding new resources, managing users and sites.

**Files & Media:**
- Managing files, media, placements, and metadata within Folio.

**Forms:**
- Building and validating forms, using custom inputs, and integrating with the admin UI.

**Emails & Templates:**
- Creating and managing email templates and newsletters.

**Configuration:**
- Engine configuration, initialization, and localization options.

**Testing:**
- Testing strategies, helpers, and best practices for Folio-based projects.

**Troubleshooting:**
- Solutions to common problems and error scenarios.

**Upgrade & Migration:**
- Guides for upgrading Folio and migrating projects to new versions.

**Extending & Customization:**
- Using generators, writing custom extensions, and overriding engine behavior.

**FAQ:**
- Short answers to common questions and practical tips.

---

## Navigation

- [Next: Architecture →](architecture.md)
- [Components](components.md) | [Atoms](atoms.md) | [Admin Console](admin.md) | [Files & Media](files.md)

---

*For more information, see the individual chapters linked above. This documentation will be updated as new content is reviewed and migrated from legacy sources.*

## Key Features at a Glance

- **Modular CMS Engine** – Pages composed of reusable CMS blocks (Atoms)
- **Modern Admin Console** – ViewComponent-based UI with generators for CRUD scaffolds
- **File & Media Library** – Uploaded files, placements, metadata, direct S3 uploads
- **Multi-site & Localization** – Multiple sites from one codebase, Traco-powered translated attributes
- **Authentication & Roles** – Devise integration, flexible abilities, optional cross-domain sessions
- **Newsletter & Mailers** – MailChimp bridge, generator-based mailers and templates
- **Extensive Generators** – Atoms, components, console scaffolds, blog, search indices, etc.

---

## Quick Start (5 Steps)

```bash
# 1. Add gems to Gemfile
bundle add folio
bundle add dragonfly_libvips
bundle add view_component

# 2. Install engine assets & migrations
rails generate folio:install
rails db:migrate

# 3. (Optional) Seed example data
rails db:seed

# 4. Start the server and open /console
rails s

# 5. Scaffold your first model in the admin
rails generate folio:console:scaffold Article
```

Refer to the [Configuration](configuration.md) chapter after installation to tailor settings.

---

## Directory Structure (Engine-Driven)

```
app/
  components/folio/      # ViewComponents (UI)
  inputs/                # Custom Simple-Form inputs
  models/folio/          # Engine models (Site, Page, Atom…)
  controllers/folio/     # Public & admin controllers
  overrides/             # Safe place for engine overrides
  cells/                 # Legacy Trailblazer Cells (deprecated)
lib/generators/folio/    # Rich set of generators
```

See individual chapters for deeper dives into components, atoms, files, etc.

---

## System Requirements

- Ruby >= 3.0
- Rails >= 6.1
- PostgreSQL (recommended), Redis (for Sidekiq)
- Image processing tools: **libvips**, **jpegtran**, **exiftool**, **cwebp**, **gifsicle**
- For video previews in tests: **ffmpeg**

Ensure these binaries are present on CI / production servers.

---

## Conventions & Roadmap

- New UI code should use **ViewComponent**; **Trailblazer Cells** remain for legacy only.
- Follow **BEM** for SASS class names.
- Place project-specific patches in `app/overrides/` to stay upgrade-safe.
- Prefer generators over hand-written boilerplate.

--- 