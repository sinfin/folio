---
name: folio-icons
description: >-
  Add or update icons in the Folio engine or a Folio host app icon set: export
  from Figma, place SVG in the icon source directory, normalize fills/strokes
  to currentColor, run bin/icons, restart Rails so sprite and YAML metadata
  load.
---

# Folio icon sets

Use this when adding or replacing SVGs in the shared Folio UI icon set inside
this gem, or in a Folio application that ships its own icon pipeline.

The Folio engine paths below are the default reference. Host applications often
have their own `bin/icons`, source icon directory, generated sprite, and metadata
paths, but the add-normalize-generate-restart flow is the same. In a host app,
read that app's `bin/icons` first and use the paths it configures.

## Steps

1. **Export from Figma** to a local file (example: `~/Downloads/creation.svg`).

2. **Copy** the file to `data/icons/<name>.svg`. The basename without `.svg` is
   the icon **name** (e.g. `creation.svg` → `folio_icon(:creation)` /
   `Folio.Ui.Icon.data("creation", ...)`). Use the same snake_case style as
   existing files (e.g. `arrow_u_right_top.svg`).

3. **Normalize colors** so icons inherit CSS `color`:
   - Replace hardcoded **fill** values such as `fill="black"` with
     `fill="currentColor"` on shapes that should theme.
   - Do the same for **stroke** when the icon uses strokes (e.g. `stroke="#000"`
     → `stroke="currentColor"`).
   - Keep structural values such as `fill="none"` on the root `<svg>` unless
     you deliberately want a filled canvas.

4. **Run** `bin/icons` from the project root that owns the icon set. In the
   Folio engine repository, it regenerates
   `app/assets/images/folio_svg_sprite.svg` and `data/folio_icons.yaml` (do not
   edit the YAML by hand). In a host application, use that app's `bin/icons` and
   generated paths instead.

   If the script exits asking for `npm install`, ensure
   `test/dummy/node_modules/.bin/svg-sprite` exists (install npm dependencies
   under `test/dummy` in this repo).

5. **Restart** the Rails dev server. `Folio::Ui::IconCell::ICONS` is loaded from
   `data/folio_icons.yaml` at class load time; without a restart, new icon
   names will not resolve. Hard-refresh the browser if the sprite SVG appears
   cached.

## Verify

- After `bin/icons`, confirm `data/folio_icons.yaml` contains a key matching your
  basename (without `.svg`).
- Render the icon by name in the UI or console to confirm the sprite reference.

## Host apps

Applications using Folio commonly ship their own `bin/icons`. Treat the local
app as the owner of its icon set: add the SVG to the app's configured icon
source directory, normalize themeable fills/strokes to `currentColor`, run the
app's `bin/icons`, and verify the generated app sprite/metadata. Do not assume
the engine filenames or `data/` paths when working in a host app.
