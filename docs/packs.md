# Packs

Folio uses packs for optional, self-contained engine features. A pack lives in
`packs/<name>` and has its own `package.yml`, runtime code, migrations, locales,
tests and optional railtie.

Packwerk is used as the static boundary check. Run it from the Folio root:

```bash
rake app:packwerk:validate
rake app:packwerk:check
```

The commands execute Packwerk from `test/dummy`, because Packwerk needs a Rails
application context. `test/dummy/packwerk.yml` includes the Folio engine root and
`packs/*`.

## Runtime Loading

Enabled packs are listed in `Folio.enabled_packs`. The default is:

```ruby
Folio.enabled_packs # => [:ai]
```

The engine loader adds these runtime paths when a pack is enabled:

- `app/models`, `app/models/concerns`
- `app/components`, `app/components/concerns`
- `app/controllers`, `app/controllers/concerns`
- `app/helpers`, `app/jobs`, `app/mailers`, `app/services`
- `app/lib`, `app/cells`
- `app/views`
- `config/locales/**/*.yml`
- `db/migrate`

Asset paths from all packs are added to the asset pipeline so shared manifests
can safely reference sidecar JavaScript/CSS even when a pack is runtime-disabled.
Disabled packs must still not render UI or load Ruby code.

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

`packs/ai` owns the reusable AI prompt/suggestion functionality:

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
