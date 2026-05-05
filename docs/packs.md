# Packs

Folio uses packs for optional, self-contained engine features. A pack lives in
`packs/<name>` and has its own `package.yml`, runtime code, migrations, locales,
tests and optional railtie.

Packwerk is used as the static boundary check. Run it from the Folio root:

```bash
bundle exec rake app:packwerk:validate
bundle exec rake app:packwerk:check
```

The commands execute Packwerk from `test/dummy`, because Packwerk needs a Rails
application context. `test/dummy/packwerk.yml` includes the Folio engine root and
`packs/*`.

## Packwerk Commands

Use `app:packwerk:validate` to verify Packwerk configuration and package
manifests. This checks that `packwerk.yml`, `package.yml` files, package paths
and the application structure are valid enough for Packwerk to run. It does not
check source code for dependency violations.

Use `app:packwerk:check` to enforce package boundaries in source code. This runs
the dependency check against included Ruby files and fails on unlisted
violations, stale todo entries or strict-mode violations.

## Runtime Loading

Enabled packs are listed in `Folio.enabled_packs`. The default is:

```ruby
Folio.enabled_packs # => []
```

Enable optional packs explicitly in the host application before the engine
initializers run:

```ruby
Folio.enabled_packs = [:ai]
```

The engine loader adds these runtime paths for enabled packs:

- `app/models`, `app/models/concerns`
- `app/components`, `app/components/concerns`
- `app/controllers`, `app/controllers/concerns`
- `app/helpers`, `app/jobs`, `app/mailers`, `app/services`
- `app/lib`, `app/cells`
- `app/views`
- `config/locales/**/*.yml`
- `db/migrate`

Asset paths from all packs are added to the asset pipeline so pack manifests can
reference component sidecar JavaScript/CSS through Sprockets. Enabled packs
declare their logical asset names from their module, and Folio includes those
assets with `Folio.enabled_pack_assets(type)`. The engine does not check logical
asset file presence on each request.

Pack-owned asset names should use `folio_pack_<pack_name>`:

```ruby
module Folio::Ai
  PACK_ASSETS = {
    javascripts: %w[folio_pack_ai],
    stylesheets: %w[folio_pack_ai],
  }.freeze

  def self.pack_assets
    PACK_ASSETS
  end
end
```

Disabled packs must not render UI or load pack runtime code.

If the pack has `lib/folio/<pack>.rb`, Folio requires it. Use that file to define
the pack namespace and require a railtie.

## Package Boundaries

Root Folio code must not reference optional pack constants directly. Use one of
these patterns instead:

- A generic extension point in root code, implemented by the pack.
- A concern included from the pack railtie.
- A `to_prepare` override in `packs/<name>/app/overrides`.
- A host-app initializer that registers app-specific behavior.

The root `package.yml` can depend on the host app because Folio is an engine and
has historical app extension points. Optional features should depend on root
Folio, not the other way around.

## Generators

Folio generators support `--pack=<name>` for files that belong to `app/` or
`test/`:

```bash
rails generate folio:component /folio/console/ai/panel --pack=ai
rails generate folio:console:scaffold folio/ai/report --pack=ai
```

Configuration files, root files and host-app setup files intentionally stay in
the application root unless a generator explicitly supports packing them.

## AI Pack

`packs/ai` owns the reusable AI prompt/suggestion functionality. The canonical
integration guide is [`docs/features/ai_prompts.md`](features/ai_prompts.md);
agent workflows should use
[`folio-ai-inputs`](../.skills/folio-ai-inputs/SKILL.md) when wiring concrete
Console inputs.

The AI pack is disabled by default. Host applications opt in with
`Folio.enabled_packs = [:ai]` and configure the feature through
`Folio::Ai.configure`.

- prompt registry, provider adapters, prompt composition and response handling
- site prompt settings and validation
- user instruction persistence
- console site settings component
- reusable text suggestions component and Stimulus controller
- SimpleForm text-input decoration through a generic root hook
- controller concern for host-app suggestion endpoints
- TipTap/plain-text context helper

Host applications own field registration, concrete routes, authorization,
record loading, context building and domain-specific aggregate actions.
