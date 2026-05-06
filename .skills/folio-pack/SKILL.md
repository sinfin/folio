---
name: folio-pack
description: >-
  Folio optional pack boundary and namespace rules. Use when editing files in
  optional pack directories, adding pack controllers/components/models/lib
  code, wiring routes to pack code, or moving reusable behavior between a host
  app, the Folio engine, and an optional pack.
---

# Folio Pack

## Boundary

- Keep every pack-owned constant under that pack namespace. For `packs/ai`,
  use `Folio::Ai::*`; console-facing code uses `Folio::Ai::Console::*`, not
  `Folio::Console::*`.
- Match file paths to constants inside the pack. Example:
  `packs/ai/app/controllers/folio/ai/console/api/text_suggestions_controller.rb`
  defines `Folio::Ai::Console::Api::TextSuggestionsController`.
- A pack may expose engine routes in normal Folio URL space, but route entries
  must explicitly point to the pack controller namespace when it differs from
  the URL namespace.
- Keep reusable pack behavior in `packs/<name>`. Keep host-specific labels,
  record context, demo data, rollout decisions, and app-specific aggregate
  workflows in the host app.

## Components And Assets

- Use the Folio component generator with `--pack=<name>` for new pack
  ViewComponents whenever possible.
- Pack component BEM names follow their actual constant namespace. Do not use
  the `Folio::Console` special `f-c` prefix for `Folio::<Pack>::Console`
  components unless a component already established that block name.
- Keep pack assets in the pack manifests and require/import colocated sidecars
  from there.

## Routes

- Prefer explicit `to:` mappings when a route URL is intentionally shared with
  engine conventions but the controller constant lives in a pack.
- Do not create host-app routes or per-model endpoints for reusable pack
  behavior unless the feature genuinely requires host-owned request handling.
