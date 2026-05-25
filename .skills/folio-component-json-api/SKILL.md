---
name: folio-component-json-api
description: >-
  Folio “HTML over wire” JSON APIs: controllers use render_component_json so the
  response body is JSON with a string "data" key holding rendered ViewComponent
  HTML; JavaScript uses Folio.Api.apiGet/apiPost and response.data, not pure
  domain JSON for client-side rendering. Use when adding or changing
  render_component_json, console/API endpoints that return component fragments,
  or consumers of response.data as HTML.
---

# Folio component JSON (HTML over wire)

Folio often serves **UI fragments** from API-style controllers by rendering a
**ViewComponent** into JSON: the envelope is JSON, but **`data` is an HTML
string**, not a typed payload for JavaScript to interpret as business objects.

Reference flow in the codebase: AI text suggestions
(`Folio::Ai::Console::Api::TextSuggestionsController` and
`packs/ai/app/assets/javascripts/folio/ai/input.js`).

## Example: AI text suggestions

Do **not** expose suggestions as a JSON array for the browser to turn into DOM
nodes (duplicate templates, I18n, and error UI in JavaScript):

```json
{ "suggestions": ["First draft", "Second draft", "Third draft"] }
```

Instead, build a **single ViewComponent** that already knows how to render
chips, errors, meta, and loading state from a Ruby result object. The controller
returns that markup inside the usual envelope—**`data` is one HTML string**:

```ruby
# Folio::Ai::Console::Api::TextSuggestionsController (simplified)
render_component_json(
  Folio::Ai::Console::TextSuggestionsComponent.new(
    result: suggestion_result(instructions:, persist_instructions:),
    component_id: component_id,
    field_label: field_label,
    # …other display-only args
  )
)
```

The Stimulus side fetches with **`Folio.Api.apiGet` / `apiPost`** and mounts
**`response.data`** (for example `handleHtml(response.data)` in
`folio/ai/input.js`)—no client-side loop over suggestion strings to build HTML.

## When to use

- Replace or inject **partial page UI** (panels, modals, lists, form slices)
  while keeping **one rendering pipeline** (Slim, helpers, I18n, component
  tests).
- Share behavior with **non-JS** consumers that still benefit from the same
  component (tests assert `parsed_body["data"]` markup).
- Prefer this over duplicating presentation logic in **JSON serializers** when
  the deliverable is **HTML**.

## When not to use

- **Domain JSON** for charts, native apps, or scripts that need structured
  fields: use serializers, `render json:`, or a dedicated JSON API.
- **Raw HTML responses** (`Content-Type: text/html`, body is markup only): use
  normal `render html:` / `render_to_string` and **`Folio.Api.apiHtmlGet` /
  `apiHtmlPost`**, not `render_component_json`.

## Server

1. Include **`Folio::RenderComponentJson`** (already included via
   `Folio::ApiControllerBase` on `Folio::Console::Api::BaseController` and related
   bases).
2. In the action:

   ```ruby
   render_component_json(MyComponent.new(...))
   ```

   Optional keyword arguments: `meta:`, `pagy:`, `flash:`, `status:`,
   `cache_key:`.

3. For **collections**, use `render_component_collection_json` (see
   `Folio::RenderComponentJson`).

Rendering is implemented by **`app/views/folio/component_json.json.erb`**: the
body looks like `{ "data": "<escaped html string>"[, "meta": ...] }`. The
**`data` value is always a string** (the rendered component HTML).

## JavaScript

- Call **`window.Folio.Api.apiGet`**, **`apiPost`**, **`apiPatch`**, etc. They
  set `Accept: application/json` and parse the body as JSON
  (`app/assets/javascripts/folio/api.js`).
- Read the fragment from **`response.data`** (string) and inject or parse as
  HTML (e.g. `innerHTML`, `insertAdjacentHTML`, or a dedicated handler).
- **`Folio.Api.apiHtmlGet` / `apiHtmlPost`** are for endpoints that return **raw
  HTML** bodies, not the component-JSON envelope—do not mix them with
  `render_component_json` responses.

Successful responses still run **`Folio.Api.flashMessageFromMeta`** when `meta`
includes flash data.

## Integration tests

- Issue requests with **`as: :json`** (or headers that expect JSON) so Rails
  treats the response as JSON.
- Assert on markup via **`response.parsed_body["data"]`** (optionally wrap in
  `Capybara.string(...)` for CSS assertions).

Example helper pattern:

```ruby
def response_component_html
  response.parsed_body["data"]
end
```

## Cross-skills

- **folio-view-component**: build the component rendered into `data`.
- **folio-javascript**: `Folio.Api` conventions and StandardJS.
- **folio-pack**: pack-scoped controllers under `packs/<name>` (namespace routes
  and constants consistently).

## Other examples in Folio

Controllers using `render_component_json` include (non-exhaustive): file
console API (`Folio::Console::Api::FileControllerBase` and related),
`Folio::Console::Api::LinksController`, `Folio::Console::Api::TiptapController`,
`Folio::Api::NewsletterSubscriptionsController`, dummy search autocomplete, and
the AI text suggestions API above.
