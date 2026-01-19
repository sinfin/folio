# Packs Architecture

Folio uses a **packs** architecture to organize optional features into self-contained modules. This allows for cleaner code organization, easier feature management, and the ability to enable or disable features per application.

---

## What Are Packs?

Packs are self-contained feature modules that live in the `packs/` directory. Each pack can contain:

- **Models** - ActiveRecord models and concerns
- **Components** - ViewComponent classes with sidecar assets (JS/CSS)
- **Controllers** - Controller classes and concerns
- **Helpers** - Helper modules
- **Jobs** - ActiveJob classes
- **Mailers** - ActionMailer classes
- **Migrations** - Database migrations specific to the pack
- **Views** - View templates
- **Tests** - Test files organized by type
- **Factories** - FactoryBot factory definitions
- **Railtie** - Rails integration code (initializers, callbacks, etc.)

Packs are **optional** - they can be enabled or disabled per Rails application via configuration.

### Packwerk Integration

Folio uses **Packwerk**, Shopify's static analysis tool for enforcing modularity in Rails applications. Each pack has a `package.yml` file that declares its dependencies, and Packwerk ensures these boundaries are respected.

This architecture is inspired by **Shopify's modular monolith** approach. Shopify uses a similar structure to organize their large Rails codebase into self-contained packages that enforce boundaries and dependencies. Key benefits:

- **Explicit dependencies** - Each pack declares what it depends on
- **Static analysis** - Violations are caught before runtime
- **Enforced boundaries** - Prevents accidental coupling between packs

---

## Directory Structure

A typical pack follows this structure:

```
packs/
├── cache/                                # Simple pack (models only)
│   ├── package.yml                       # Packwerk configuration
│   ├── app/
│   │   └── models/
│   │       └── folio/
│   │           ├── cache.rb              # namespace module
│   │           └── cache/
│   │               └── version.rb        # models
│   ├── db/
│   │   └── migrate/
│   │       └── 20260119095958_create_folio_cache_versions.rb
│   ├── lib/
│   │   └── folio/
│   │       └── cache.rb                  # railtie for Rails integration
│   └── test/
│       ├── factories/
│       │   └── folio/
│       │       └── cache.rb              # factory definitions
│       └── models/
│           └── folio/
│               └── cache/
│                   └── version_test.rb   # test files
│
└── tiptap/                               # Full-featured pack (with components)
    ├── package.yml
    ├── app/
    │   ├── components/
    │   │   └── folio/
    │   │       └── console/
    │   │           └── tiptap/
    │   │               └── autosave_info/
    │   │                   ├── autosave_info_component.rb
    │   │                   ├── autosave_info_component.js    # sidecar JS
    │   │                   └── autosave_info_component.sass  # sidecar CSS
    │   ├── controllers/
    │   │   └── folio/
    │   │       └── tiptap_controller.rb
    │   └── models/
    │       └── folio/
    │           └── tiptap/
    ├── db/
    │   └── migrate/
    ├── lib/
    │   └── folio/
    │       └── tiptap.rb
    └── test/
```

---

## Enabling/Disabling Packs

Packs are configured in your Rails application's initializer:

```ruby
# config/initializers/folio.rb
Folio.configure do |config|
  # Enable specific packs
  config.enabled_packs = [:cache]

  # Or add to defaults
  # config.enabled_packs += [:tiptap]

  # Or remove from defaults
  # config.enabled_packs -= [:cache]
end
```

By default, the `cache` pack is enabled. To disable it:

```ruby
Folio.configure do |config|
  config.enabled_packs = []
end
```

---

## How Packs Work

When a pack is enabled:

1. **Autoload paths** are added for all `app/` subdirectories:
   - `app/models`, `app/models/concerns`
   - `app/components`, `app/components/concerns`
   - `app/controllers`, `app/controllers/concerns`
   - `app/helpers`, `app/jobs`, `app/lib`, `app/mailers`

2. **View paths** - `app/views` is added to Rails view paths

3. **Asset paths** - `app/components` is added to the asset pipeline, enabling sidecar assets (JS/CSS files alongside Ruby classes)

4. **Migrations** from `db/migrate` are added to Rails migration paths

5. **Railtie** is loaded from `lib/folio/<pack_name>.rb` (if it exists)

6. **Factories** from `test/factories` are loaded for tests

The pack loader runs early in the Rails initialization process (before `:set_autoload_paths`), ensuring all pack code is available when Rails loads.

### Sidecar Assets

ViewComponent sidecar assets work automatically in packs. Place JS/CSS files alongside the Ruby class:

```
packs/tiptap/app/components/folio/console/tiptap/autosave_info/
├── autosave_info_component.rb
├── autosave_info_component.js    # loaded via asset pipeline
└── autosave_info_component.sass  # loaded via asset pipeline
```

These assets are discovered by Sprockets because the pack's `app/components` directory is added to `config.assets.paths`.

---

## Available Packs

### Cache Pack (`:cache`)

Provides cache versioning functionality for tracking cache invalidation.

**Models:**
- `Folio::Cache::Version` - Tracks cache keys and versions per site

**Usage:**
```ruby
# Create a cache version
Folio::Cache::Version.create!(key: "my_cache_key", site: current_site)

# Check if a key exists
Folio::Cache::Version.exists?(key: "my_cache_key", site: current_site)
```

---

## Creating a New Pack

To create a new pack:

1. **Create the directory structure:**
   ```bash
   mkdir -p packs/my_pack/{app/models/folio/my_pack,db/migrate,lib/folio,test/{factories/folio/my_pack,models/folio/my_pack}}
   ```

2. **Create the `package.yml` (required for Packwerk):**
   ```yaml
   # packs/my_pack/package.yml
   enforce_dependencies: true

   dependencies:
     - "../.."  # depends on core Folio engine
   ```

3. **Create the namespace module:**
   ```ruby
   # packs/my_pack/app/models/folio/my_pack.rb
   module Folio
     module MyPack
     end
   end
   ```

4. **Create the railtie (optional):**
   ```ruby
   # packs/my_pack/lib/folio/my_pack.rb
   module Folio
     module MyPack
       class Railtie < ::Rails::Railtie
         initializer "folio_my_pack.setup" do
           # Add initialization code here
         end
       end
     end
   end
   ```

5. **Add factories (if needed):**
   ```ruby
   # packs/my_pack/test/factories/folio/my_pack.rb
   FactoryBot.define do
     factory :folio_my_pack_model, class: "Folio::MyPack::Model" do
       # factory definition
     end
   end
   ```

6. **Enable the pack** in your application's initializer:
   ```ruby
   Folio.configure do |config|
     config.enabled_packs << :my_pack
   end
   ```

7. **Run Packwerk check** to verify dependencies:
   ```bash
   bundle exec packwerk check
   ```

---

## Packwerk Configuration

Folio includes Packwerk for enforcing pack boundaries. The configuration consists of:

### Root Configuration (`packwerk.yml`)

Located at `test/dummy/packwerk.yml` (the Rails app context), this defines global settings:

```yaml
include:
  - "**/*.rb"
  - "../../app/**/*.rb"
  - "../../lib/**/*.rb"
  - "../../packs/**/*.rb"
exclude:
  - "{bin,node_modules,tmp,vendor}/**/*"
package_paths:
  - "."        # host app (test/dummy)
  - "../.."    # core Folio engine
  - "../../packs/*"  # optional packs
cache: true
```

### Engine Load Paths Extension

Packwerk by default only includes paths under `Rails.root`. Since Folio is an engine that lives outside the dummy app, we extend packwerk via `test/dummy/config/initializers/packwerk.rb` to include the engine's load paths. This enables packwerk to resolve constants like `Folio::ApplicationRecord` when checking pack dependencies.

### Pack Configuration (`package.yml`)

Each pack has its own `package.yml` that declares:

- **`enforce_dependencies`** - When `true`, the pack can only use code from declared dependencies
- **`dependencies`** - List of packs this pack depends on (use `"."` for core Folio)

Example:
```yaml
enforce_dependencies: true
dependencies:
  - "../.."           # core Folio engine
  - "../other_pack"   # another pack (sibling directory)
```

**Note:** Privacy enforcement (`enforce_privacy`) requires the `packwerk-extensions` gem.

### Running Packwerk

Packwerk requires a Rails application context to resolve constants.

**From the engine root:**
```bash
rake app:packwerk:check      # Check for violations
rake app:packwerk:validate   # Validate configuration
rake app:packwerk:update_todo  # Update violation TODO list
```

**From test/dummy directory:**
```bash
bundle exec packwerk check
bundle exec packwerk validate
bundle exec packwerk update-todo
```

**For host applications using Folio:**
```bash
bundle exec packwerk check
```

**Tip:** In a host Rails application, you can generate a binstub with `bundle binstub packwerk` to use `bin/packwerk` instead.

---

## Benefits of Packs

- **Clean organization** - All code for a feature lives in one directory
- **Easy deletion** - Remove a pack by deleting its directory and removing from `enabled_packs`
- **Optional features** - Enable only what you need per application
- **Self-contained** - Models, migrations, tests, and factories are co-located
- **Enforced boundaries** - Packwerk prevents accidental coupling between packs
- **Future-proof** - Packs can be extracted to separate gems if needed

---

## Migration from Old Structure

If you're migrating existing code to a pack:

1. Move models from `app/models/folio/<feature>/` to `packs/<feature>/app/models/folio/<feature>/`
2. Move migrations from `db/migrate/` to `packs/<feature>/db/migrate/`
3. Move tests from `test/models/folio/<feature>/` to `packs/<feature>/test/models/folio/<feature>/`
4. Move factories from `test/factories.rb` to `packs/<feature>/test/factories/folio/<feature>.rb`
5. Create a railtie in `packs/<feature>/lib/folio/<feature>.rb` if needed
6. Create `packs/<feature>/package.yml` with Packwerk configuration
7. Add the pack to `Folio.enabled_packs` (or configure in your app)
8. Run `bundle exec packwerk check` to verify no boundary violations

---

## Navigation

- [← Back to Architecture](architecture.md)
- [Configuration](configuration.md) | [Testing](testing.md) | [Components](components.md)

---

*For questions or issues with packs, see the [FAQ](faq.md) or [Troubleshooting](troubleshooting.md).*
