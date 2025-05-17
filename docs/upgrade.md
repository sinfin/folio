# Upgrade & Migration

This chapter aggregates the most relevant upgrade paths and migrations for the Folio Rails Engine. Content is derived from the original wiki articles and verified against the current codebase.

---

## Checklist Before You Start

1. Commit and push all pending changes.
2. Run the test suite and ensure it is green.
3. Create a fresh backup of the database and uploaded files.
4. Read the release notes for every Folio version you are jumping over.

---

## Upgrading a Project to Rails 6

*Based on the original wiki article **Upgrading-projects-to-rails-6**; verified with the engine code.*

1. **Update Gemfile**
   ```ruby
   gem "rails", "~> 6.1.7"
   gem "webpacker", "~> 5.4" # if you still use Webpacker
   ```
2. **Bundle update**
   ```sh
   bundle update rails
   ```
3. **Zeitwerk** – Ensure all autoload paths follow Zeitwerk conventions: file names must match class names.
4. **Credentials** – Rails 6 expects `config/master.key` and `config/credentials.yml.enc`.
5. **Webpacker** – Run `bundle exec rails webpacker:install` if you haven't migrated to import-map / esbuild yet.
6. **Run generators**
   ```sh
   rails app:update
   rails railties:install:migrations
   rails db:migrate
   ```
7. **Test & Fix** – Run the full test suite and fix deprecations.

---

## Console Rework Migration (Folio ≥ 3.0)

*Based on wiki article **Upgrading-to-console-rework***

Folio 3 introduced a redesigned admin console built on ViewComponent.

1. Update the engine in the Gemfile:
   ```ruby
   gem "folio", "~> 3.0"
   ```
2. Bundle update.
3. Run the console scaffold generator for each resource you still manage via the old Cell-based UI:
   ```sh
   rails generate folio:console:scaffold Article
   ```
4. Remove legacy `app/cells/**/console` directories once you have migrated.

---

## Migrating Atoms to JSON-based Data

*Based on wiki article **Migrating-code-to-JSON-data-based-atoms***

Older projects stored atom attributes in dedicated columns. Folio now stores atom data in the `data` JSONB column.

1. Generate a migration to copy existing attributes:
   ```sh
   rails generate migration MigrateAtomsToJsonData
   ```
2. Inside the migration iterate over each atom type and move attributes into `data`:
   ```ruby
   def up
     Folio::Atom::Text.find_each do |atom|
       atom.update!(data: { content: atom.read_attribute(:content) })
     end
   end
   ```
3. Remove the old columns after verifying the content.
4. Update the corresponding ViewComponent to read from `data.fetch(:content)`.

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