# AI Prompts

## Status

Folio AI pack implementation slice is implemented on branch `feat/ai-prompts`
and is pending review against this draft before publication.
The document is both the implementation plan and the reusable contract for host
applications.

This document intentionally stays product-agnostic. Client-specific prompt copy,
site names, and custom editorial workflows belong in host applications and in
runtime site settings, not in the reusable Folio AI pack.

Implemented in the Folio `:ai` pack:

- AI registry, field metadata, provider adapters, prompt composition, response
  normalization, and user-instruction persistence.
- Global feature flag, ENV kill switch, per-site settings, per-field prompt and
  enabled gates.
- Site settings validation against registered integrations, registered fields,
  and configured providers while Folio AI is globally enabled.
- Console site settings tab for registered promptable fields.
- Auto-attachment for supported standard SimpleForm `string` and `text` inputs
  inside an explicit AI form context.
- Public `Folio::Console::Ai::TextSuggestionsComponent` for manual custom-field
  wiring.
- Shared Stimulus state machine for loading, error, suggestions, accept, copy,
  ghost undo, close, and regenerate/save-instructions.
- Reusable controller concern for host-app endpoint contracts.
- TipTap/plain-text helper for context builders.
- Cost/rate-limit guards and safe instrumentation events without prompts or
  generated content.

The root Folio package only provides generic extension points and pack loading.
AI-specific model concerns, controller concerns, SimpleForm decoration, locales,
migrations, components and tests live under `packs/ai`.

## Goals

- Reusable AI prompt management for Folio-based applications.
- Per-site, per-field default prompts without hardcoding application-specific
  field names into engine code.
- Optional feature: if AI is not enabled, neither site-level prompt fields nor
  editor-side AI controls are rendered.
- Shared admin/editor behavior across apps, with clean hooks for app-specific
  context building.
- Built-in provider adapters for OpenAI and Anthropic, with configurable model
  overrides and cheaper fallbacks.

## Non-Goals

- Shipping default prompt copy for specific customers or sites.
- Encoding application-specific business rules such as multi-field or
  channel-specific bulk generation into the Folio AI pack.
- Forcing every host app to use the same controller or authorization layer.
- Hardcoding rich-text output semantics for every possible editor target.

## Existing Folio Hooks To Reuse

- Site settings already flow through [`Folio::Site`](../../app/models/folio/site.rb),
  [`SitesController`](../../app/controllers/folio/console/sites_controller.rb),
  and the shared site form tabs in
  [`app/views/folio/console/sites/_form.slim`](../../app/views/folio/console/sites/_form.slim).
- Site tabs are already driven by `console_form_tabs` and
  [`Folio::Console::TabsHelper`](../../app/helpers/folio/console/tabs_helper.rb).
- Folio TipTap already stores a plain-text representation next to the structured
  JSON content; host apps can reuse that instead of walking ProseMirror trees for
  the common plain-text case. See [Tiptap](../tiptap.md).

## Ownership Boundary

| Folio AI pack owns | Host app owns |
| --- | --- |
| Feature flagging and site-level availability rules | Which models and forms opt in |
| Prompt registry and validation for registered fields | Resource loading and authorization |
| Site-level prompt storage | Context building for a specific record type |
| User instruction persistence | App-specific aggregate actions such as multi-field bulk generation |
| Shared AI suggestion panel component and JS state machine | AI form context wiring for concrete resources |
| Auto-attachment to supported Folio SimpleForm inputs | Custom input/component wiring and aggregate workflows |
| Prompt composition pipeline | Rich-text output mapping for app-owned editors |
| Provider adapter interface and built-in providers | Client-specific prompt text entered by admins |
| Reusable TipTap plain-text helpers | Field labels, ordering, and site-specific rollout decisions |

## Boundary Decision Rule

Use this rule when a ticket, design note, or host-app requirement is ambiguous:

- Put it in the Folio AI pack when the behavior can be reused by another Folio
  application without knowing the concrete model class, form layout, editorial
  field names, distribution channels, or authorization rules.
- Keep it in the host app when it depends on a concrete resource, route shape,
  permission model, field taxonomy, aggregate workflow, rollout decision, prompt
  copy, or rich-text editor contract.
- If product acceptance criteria from a host app contradict this boundary,
  implement the reusable Folio contract first and leave the app-specific
  behavior to the host-app integration.

## V1 Decisions

These decisions are part of the implementation plan unless explicitly reopened.

- The Folio AI pack ships the reusable service layer, provider adapters, persistence,
  response contract, and editor-side suggestion panel. Host applications keep
  thin resource-specific controllers for lookup, authorization, and route shape.
- Folio AI v1 supports plain-text suggestions. Structured rich-text output is an
  extension point, not a v1 requirement. Host apps must not fake editor JSON until
  the target editor contract is known.
- The base installation is documented manual setup. A generator is optional
  later, but is not required for v1.
- AI never overwrites a field automatically. A suggestion affects a form field
  only after the editor accepts a suggestion card.
- User instructions are saved only by an explicit action in the AI panel. The
  same action also regenerates suggestions for the current panel context.
- Usage tracking is required in v1, but tracked events must not include full
  prompt text, record body, or generated suggestion content by default.

## Current Folio API

### Host-App Usage Guide

Use this sequence when a Folio-based application wants to enable AI suggestions
for one or more editor inputs.

1. Keep the `:ai` pack enabled. The pack is enabled by default through
   `Folio.enabled_packs`; disabling the pack must remove the feature entirely.
2. Run the AI pack migrations from `packs/ai/db/migrate`.
3. Configure the feature and providers in the host app:

   ```ruby
   Rails.application.config.folio_ai_enabled = ENV["FOLIO_AI_ENABLED"].present?
   Rails.application.config.folio_ai_default_provider = :openai
   Rails.application.config.folio_ai_provider_models = {
     openai: "gpt-5.5",
     anthropic: "claude-opus-4-7",
   }
   Rails.application.config.folio_ai_model_fallback_enabled = true
   Rails.application.config.folio_ai_model_catalog_cache_ttl = 1.hour
   ```

4. Configure provider credentials with `OPENAI_API_KEY` and/or
   `ANTHROPIC_API_KEY`. The environment kill switch `FOLIO_AI_DISABLED`
   suppresses all runtime AI behavior even when the app config enables it.
5. Optionally expose curated model labels and cost tiers in site settings:

   ```ruby
   Rails.application.config.folio_ai_provider_model_options = {
     openai: {
       "gpt-5.5" => { label: "GPT-5.5", cost_tier: "premium", default: true },
     },
     anthropic: {
       "claude-opus-4-7" => { label: "Claude Opus 4.7", cost_tier: "premium" },
     },
   }
   ```

   If API credentials are available, Folio lists live provider models and caches
   them in `Rails.cache` for `folio_ai_model_catalog_cache_ttl`. Configured
   metadata only enriches those options with labels/cost tiers. If the live
   catalog cannot be fetched, Folio falls back to configured options. If a saved
   site model later disappears, Folio keeps it visible as unavailable and, when
   `folio_ai_model_fallback_enabled` is true, generation falls back to the
   provider default model and returns a warning for the editor UI.
6. Register promptable fields after Rails initialization:

   ```ruby
   Rails.application.config.after_initialize do
     Folio::Ai.register_integration(:content_editor,
                                    label: "Content editor",
                                    fields: [
                                      Folio::Ai::Field.new(key: :title,
                                                           label: "Title",
                                                           auto_attach: true,
                                                           input_types: %i[string],
                                                           character_limit: 120),
                                      Folio::Ai::Field.new(key: :summary,
                                                           label: "Summary",
                                                           auto_attach: true,
                                                           input_types: %i[text],
                                                           character_limit: 400),
                                    ])
   rescue ArgumentError => e
     raise unless e.message.include?("already registered")
   end
   ```

   Use `auto_attach: true` only for standard SimpleForm `string` or `text`
   inputs that should receive AI controls automatically inside an explicit form
   context. Custom inputs and aggregate workflows should use manual wiring.
7. Add a host-app endpoint that includes
   `Folio::Console::Ai::SuggestionsControllerBase`. The controller stays thin:
   load and authorize the record, return context, and provide record-specific
   eligibility.
8. Build context with reusable plain-text helpers where possible. For TipTap
   fields prefer `Folio::Tiptap::PlainText.from_value(...)`; do not serialize
   raw editor JSON into prompts unless the host app has a reviewed mapper.
9. Wrap the concrete form section in `folio_ai_form_context` to enable
   auto-attachment for registered standard fields.
10. Render `Folio::Console::Ai::TextSuggestionsComponent` manually for custom
    inputs, rich-text wrappers, unusual placement, or app-owned aggregate
    workflows.
11. Enable AI and fill default prompts per site and field in Console site
    settings. A field remains hidden from editors until its site prompt is
    non-blank.
12. Verify the full UI lifecycle on a persisted record: hidden when disabled,
    loading, missing context, provider error/timeout, variants, copy, accept,
    manual edit detach, ghost undo, close, instruction persistence, regenerate,
    model fallback warning, and rate-limit behavior.

### Site Settings Tab

When `Rails.application.config.folio_ai_enabled` is true and at least one AI
integration is registered, the AI pack prepends `Folio::Site#console_form_tabs`
and adds the `ai_prompts` tab. The tab renders
`Folio::Console::Ai::SiteSettingsComponent` and stores values in
`folio_sites.ai_settings`.

Field availability remains conservative:

1. Global Folio AI flag and `FOLIO_AI_DISABLED` kill switch.
2. Site-level `ai_settings.enabled`.
3. Registered integration and field.
4. Field-level `enabled` flag.
5. Non-blank field default prompt.
6. Host-app eligibility check.

When Folio AI is globally enabled, site settings are also validated before save:
unknown integrations, unknown fields, invalid nested structures, and unknown
provider keys are rejected. Blank prompts remain valid configuration, but keep
the field unavailable until an admin fills a default prompt.

### Auto-Attachment For Standard Fields

Host applications opt a form into AI attachment with
`folio_ai_form_context`. Folio then enriches eligible standard SimpleForm
`string` and `text` inputs if the registered field has `auto_attach: true`.

```slim
= folio_ai_form_context(integration_key: :content_editor,
                        endpoint: console_article_ai_suggestions_path(@article),
                        record: @article,
                        current_state_policy: :persisted_record) do
  = f.input :title
  = f.input :perex, as: :text, character_counter: 400
```

The form context is deliberately explicit. A configured site prompt alone does
not attach AI controls to arbitrary forms.

### Manual Custom-Field Wiring

Custom ViewComponents, custom SimpleForm inputs, rich-text editors, and unusual
placements should render the same component manually:

```ruby
render Folio::Console::Ai::TextSuggestionsComponent.new(
  integration_key: :content_editor,
  field_key: :social_text,
  endpoint: console_article_ai_suggestions_path(@article),
  target_selector: "#article_social_text",
  user_instructions: Folio::Ai::UserInstruction
    .find_or_initialize_for(user: current_user,
                            site: Folio::Current.site,
                            integration_key: :content_editor,
                            field_key: :social_text)
    .instruction,
  character_limit: 250,
)
```

Manual wiring must still use `Folio::Ai::Availability` or equivalent host-app
gates before rendering the component.

### Host-App Endpoint

Folio provides `Folio::Console::Ai::SuggestionsControllerBase`. A host app
should include it in a thin authenticated controller and override only the
resource-specific methods:

```ruby
class Console::Articles::AiSuggestionsController < Folio::Console::Api::BaseController
  include Folio::Console::Ai::SuggestionsControllerBase

  private
    def folio_ai_context
      Articles::AiContextBuilder.new(article: @article).call
    end

    def folio_ai_host_eligible?
      @article.persisted? && folio_ai_context[:body_text].present?
    end
end
```

The response contract is:

```json
{
  "data": {
    "suggestions": [
      { "key": "1", "text": "Suggested text", "char_count": 182, "meta": {} }
    ],
    "user_instructions": "Last saved instructions",
    "provider": "openai",
    "model": "gpt-5.5",
    "warnings": []
  }
}
```

### Context Serialization Helpers

For TipTap content, host apps can use:

```ruby
Folio::Tiptap::PlainText.from_value(record.tiptap_content)
```

The helper prefers the stored plain-text field when present and falls back to a
safe ProseMirror text walk for common text nodes.

### Observability

`Folio::Ai.track` instruments `ActiveSupport::Notifications` with event names
under `folio.ai.*`. The default payload allow-list includes site, user,
integration, field, provider, model, suggestion count, latency, error code, and
record class only.

### Dummy App Verification

The dummy app wires a no-credentials demo integration for local validation:

- `test/dummy/config/initializers/folio_ai.rb` enables Folio AI in development
  and registers `dummy_blog_articles`.
- `test/dummy/app/controllers/folio/console/dummy/blog/article_ai_suggestions_controller.rb`
  includes the reusable endpoint concern and uses an in-process demo adapter
  instead of OpenAI or Anthropic credentials.
- The persisted dummy blog article form wraps standard text fields in
  `folio_ai_form_context`, so `title`, `perex`, `meta_title`, and
  `meta_description` auto-attach AI controls once the current site has prompts
  configured.

Manual demosite check:

1. Start the dummy app in development.
2. Open Console site settings and enable AI prompts for the current site.
3. Fill non-blank default prompts for the dummy blog article fields.
4. Open an existing dummy blog article; new unsaved records intentionally do not
   show AI actions.
5. Click an AI action and verify loading, three variants, copy, accept, undo,
   close, persisted instructions, and regenerate without requiring provider
   credentials.

Repeatable visual capture:

```bash
RAILS_ENV=test TEST_WITH_ASSETS=1 bundle exec ruby scripts/development/capture_ai_screenshots.rb
```

The script stores PNG files under `tmp/ai-screenshots-*/folio-dummy/` and stubs
the browser API call, so provider credentials are not needed. Use it before
marking UI changes as design-ready and compare the generated states against the
approved design export or live Figma source.

The dummy adapter is for UI/contract verification only. Host applications must
provide their own context builder, authorization, route, and provider
configuration.

## Proposed Architecture

### 1. Feature Gating and Site Configuration

At the application level, Folio should default to AI being off. Runtime gates
must be layered, not collapsed into a single prompt check.

```ruby
Rails.application.config.folio_ai_enabled = false
Rails.application.config.folio_ai_provider_request_timeout = 30
Rails.application.config.folio_ai_client_request_timeout_ms = 45_000
```

Provider timeout is enforced in the server adapter boundary and maps to
`provider_timeout`. The client timeout is intentionally longer than the provider
timeout so the editor can usually show the server's normalized error response,
but still aborts a request that gets stuck in the browser, proxy, or application
server path.

If an environment variable is introduced for an operational AI kill switch, it
must be registered in [`Folio::EnvFlags`](../../lib/folio/env_flags.rb) with a
clear description so development, CI, and deploy logs show that the flag is
active. ENV flags are not a replacement for per-site rollout configuration.

Required availability gates:

1. Global app/ENV kill switch.
2. Site-level enable switch.
3. Registered integration and field.
4. Non-blank default prompt for that site and field.
5. Host app eligibility check for the current record/field.

If the global AI gate is off:

- the site settings AI tab is not rendered
- prompt textareas are not rendered
- field-level AI buttons/panels are not rendered
- AI endpoints should reject requests with `feature_disabled`

When the app-level flag is on, each site gets its own AI settings payload stored
on `folio_sites`. A JSONB column is preferable here because:

- promptable fields vary per host application
- site settings are already site-owned in Folio
- adding a new promptable field should not require a DB migration

Suggested shape:

```json
{
  "enabled": true,
  "default_provider": "openai",
  "default_model": "gpt-5.5",
  "integrations": {
    "content_editor": {
      "fields": {
        "title": {
          "enabled": true,
          "prompt": "Generate a concise headline...",
          "provider": "openai",
          "model": "gpt-5.5"
        },
        "summary": {
          "enabled": true,
          "prompt": "Summarize the content in up to 400 characters..."
        }
      }
    }
  }
}
```

If any availability gate fails, no field-level AI UI is shown.

### 1.1 Storage Contract

Suggested migrations:

- `folio_sites.ai_settings` as `jsonb`, default `{}`, `null: false`.
- `folio_ai_user_instructions` with `user_id`, `site_id`, `integration_key`,
  `field_key`, `instruction`, timestamps, and a unique index across
  `user_id/site_id/integration_key/field_key`.

Validation requirements:

- Unknown `integration_key` or `field_key` values are rejected.
- Blank default prompts make the field unavailable, not partially enabled.
- Provider and model overrides are validated against configured providers.
- User instructions are limited by length and treated as data, not trusted
  system instructions.

### 2. Prompt Registry

Host apps should register integrations and fields in a single initializer.

Illustrative DSL:

```ruby
Rails.application.config.folio_ai_registry.register(:content_editor) do |integration|
  integration.context_builder = "MyApp::Ai::ContentContextBuilder"

  integration.field(:title,
                    prompt_key: "content.title",
                    response_format: :text)

  integration.field(:summary,
                    prompt_key: "content.summary",
                    response_format: :text)
end
```

The registry should own:

- canonical prompt keys
- field ordering for the site settings tab
- human labels and help text hooks
- expected response format (`:text` now, structured formats later)
- optional char-limit lambdas
- field eligibility hooks for record-level checks
- context requirements such as required body text or required source fields
- whether the field can auto-attach to supported console inputs

Folio should not ship any application-specific prompt keys. Host apps define
them and Folio validates only against what the app registered.

Registry validation should fail fast at boot or in tests when:

- two fields register the same prompt key inside one integration
- a field has no label for site settings
- a field has no response format
- a configured site prompt references an unregistered field

### 2.1 Console Field Attachment

For supported standard console fields, AI controls should attach automatically.
The site prompt configuration alone is not enough; all of these conditions must
be true:

1. The host form declares an AI form context, including `integration_key`,
   endpoint, record identity, and current-state policy.
2. The field is registered in the Folio AI registry with `auto_attach: true`.
3. The rendered input is a supported Folio SimpleForm input type (`string` or
   `text` in v1).
4. The global/site/field availability gates pass.
5. The field is editable and the host eligibility hook returns true.

When those conditions pass, Folio should enrich the field wrapper with the AI
action icon and the data attributes needed by the shared panel controller. This
should use the existing SimpleForm `custom_html` / wrapper mechanism rather than
requiring every standard field to manually render a separate component.

Unsupported cases require explicit host-app wiring:

- custom ViewComponents that do not render a standard SimpleForm wrapper
- custom SimpleForm inputs whose DOM cannot be targeted safely
- rich-text editors until their serialization and undo contract is explicit
- aggregate workflows such as multi-field generation
- fields where the app wants custom placement, labels, or grouped UI

The automatic attachment must be conservative. If Folio cannot determine the
field key, target input, endpoint, or record readiness, it should not render the
AI action.

Folio must also expose a public manual component API for custom fields. Host
applications need to be able to render the same AI action and panel manually
next to a custom field when they provide:

- `integration_key`
- `field_key`
- target input reference or selector
- endpoint or form-level AI context reference
- response format (`plain_text` in v1; structured formats when explicitly
  supported)
- character limit, if any
- disabled/eligible state
- optional serializer hook for non-standard field values

Manual custom-field wiring must use the same availability gates, registry
metadata, provider service, prompt composition, user-instruction persistence,
response schema, tracking events, and frontend state machine as auto-attached
standard fields. It must not create a second AI implementation path.

### 3. User Instructions Persistence

User-entered instructions should be stored outside `folio_sites`, because they
belong to a user/site/field combination, not to global site settings.

Suggested table: `folio_ai_user_instructions`

Suggested columns:

- `user_id`
- `site_id`
- `integration_key`
- `field_key`
- `instruction`
- timestamps

The last saved value should be reused as the default editor-side instruction
value for the same user/site/integration/field pair.

Instruction behavior:

1. The panel opens with the last saved instruction for the current
   user/site/integration/field pair.
2. Editing the textarea changes only local panel state.
3. Clicking the save/regenerate action persists the instruction and starts a new
   generation request.
4. If provider generation fails after the instruction has been saved, the saved
   instruction remains and the panel shows the generation error.
5. The undo snapshot for the target field is not refreshed by regenerate; it
   continues to point to the field value captured when the panel was opened.

### 4. Providers and Model Selection

Folio should expose a small provider adapter interface:

- `build_request(...)`
- `generate_suggestions(...)`
- `normalize_response(...)`

Initial built-in adapters:

- OpenAI
- Anthropic

Default model IDs in the Folio AI pack:

- OpenAI: `gpt-5.5`.
- Anthropic: `claude-opus-4-7`.

Both defaults are configuration values, not hardcoded service assumptions. Host
applications should override them when the account requires a stable dated
snapshot, a cheaper model, or a provider-specific production identifier.

Folio keeps model selection as a cost-aware site setting, but provider APIs do
not expose a complete pricing contract in their model-list endpoints. Host apps
should therefore provide curated model metadata through
`config.folio_ai_provider_model_options` when labels such as "premium",
"standard", or "economy" are needed. Folio merges that metadata with the live
provider model list.

The live model catalog should:

1. Fetch available models from the provider model-list endpoint.
2. Filter the list to text-generation models relevant for AI prompts.
3. Cache the verified list through `Rails.cache` for
   `config.folio_ai_model_catalog_cache_ttl` (default: one hour).
4. Fall back to configured model options when the provider list cannot be
   verified, without blocking the settings form.
5. Keep an already selected model visible and flagged when the live list proves
   it is no longer available.

Use `Rails.cache` rather than a direct Redis dependency. Host apps that run
Folio with Redis-backed caching get Redis behavior without coupling the AI pack
to one cache store.

Provider/model overrides must resolve as a pair:

1. Field provider + field model override.
2. Field provider override + that provider's app default model.
3. Field model override + inherited provider.
4. Integration provider + integration model override.
5. Integration provider override + that provider's app default model.
6. Integration model override + inherited provider.
7. Site provider + site model override.
8. Site provider override + that provider's app default model.
9. App default provider + app default model.

This prevents invalid combinations such as an Anthropic provider override
accidentally inheriting an OpenAI model from the site default.

Runtime fallback rules:

1. If the provider rejects the selected model as missing or unavailable, Folio
   retries once with the provider's configured default model when
   `config.folio_ai_model_fallback_enabled` is true.
2. Successful fallback responses include a warning payload so the editor sees
   that generation used a fallback and the site settings must be fixed.
3. If the fallback model is also unavailable, the endpoint returns
   `provider_model_unavailable`.
4. Folio must never silently switch models without tracking the requested model,
   fallback model, provider, field, site, and warning code.

Production code should use explicit configured model identifiers or aliases from
environment/configuration rather than hardcoding them deep in the service layer.
For providers with snapshot-based model IDs, production should prefer a stable
snapshot over a moving alias unless the host app intentionally opts into alias
updates.

### 5. Prompt Composition

Prompt composition should be deterministic and centralized:

1. Engine-level guardrails
2. Site-level default prompt for the field
3. Persisted user instructions, if present
4. Current request instructions, if present
5. Normalized record context built by the host app

The site-level default prompt is mandatory. If it is blank, Folio should treat
the field as unavailable rather than trying to generate with only ad hoc user
instructions.

The composition layer must treat record content, default prompts, and user
instructions as separate message sections. User instructions may refine tone or
constraints, but they must not override engine guardrails, provider safety
settings, output schema, or field limits.

### 6. Context Serialization

Host apps should own the context builder for their resource types. Folio should
only define the interface and ship helpers for common serialization tasks.

Suggested normalized context payload:

```json
{
  "record_title": "Existing title",
  "record_summary": "Existing summary",
  "body_text": "Plain text body",
  "metadata": {
    "char_limit": 400,
    "site_slug": "example"
  }
}
```

For TipTap-backed content, Folio should ship a helper that reads the already
stored plain-text representation from the TipTap JSON payload. That keeps the
common AI use case aligned with search/export code and avoids duplicating a rich
text walker in every app.

Host apps must choose and document one current-state policy per integration:

- `persisted_record`: generation uses the last saved server state only; the UI
  must not imply that unsaved form edits affect suggestions.
- `current_form_snapshot`: generation sends the current field values and editor
  plain text from the open form; the backend still authorizes the persisted
  record and validates the snapshot shape.

For editor UIs where the body can be dirty and cannot be serialized safely,
the panel should either block generation with `record_not_ready` or ask the
editor to save first. Silent fallback from dirty form content to stale persisted
content is not acceptable.

Structured or rich-text AI output should remain an extension hook. Folio may
transport structured responses, but the final mapping to an app-owned editor
format should stay in the host application.

### 7. UI and Endpoint Contract

Folio should own the reusable suggestion panel component and its frontend state
machine:

- closed/default
- loading
- loaded suggestions
- missing context error
- provider/network error
- snapshot-based undo lifecycle

Required panel actions:

- `copy`: copies a suggestion to the clipboard and leaves the target field
  unchanged.
- `accept`: writes the suggestion to the target field, marks the card as
  selected, and shows undo for that field.
- `undo`: restores the value captured when the panel was opened and clears the
  selected card.
- `close`: closes the panel, clears panel-local suggestions and undo snapshots,
  and treats the current field value as the new origin.
- manual field edit after `accept`: clears the selected card state but keeps the
  panel open.

For auto-attached standard fields, the action icon is rendered in the input
wrapper. Clicking it opens the same shared panel below or next to the target
field according to the component layout. The panel behavior is identical whether
it was auto-attached or rendered explicitly by a host app.

Folio should also define a reusable response schema:

```json
{
  "suggestions": [
    {
      "key": "1",
      "text": "Suggested text",
      "char_count": 182,
      "meta": {
        "tone_label": "Neutral"
      }
    }
  ],
  "user_instructions": "Persisted value",
  "provider": "openai",
  "model": "gpt-5.5",
  "warnings": [
    {
      "code": "model_fallback",
      "message": "Selected model is unavailable; fallback model was used.",
      "requested_model": "retired-model",
      "fallback_model": "gpt-5.5"
    }
  ]
}
```

Response validation:

- The service should normalize provider output to the contract before the
  controller renders JSON.
- Invalid JSON, missing text, empty suggestions, or wrong response formats return
  `provider_error` with a safe message.
- Char limits are enforced after normalization; over-limit suggestions are either
  rejected or flagged according to the registered field policy.
- Suggestion count is a request/field setting with a safe default, not assumed
  from provider output.

Suggested request schema for a single field:

```json
{
  "integration_key": "content_editor",
  "field_key": "summary",
  "instructions": "Make the summary more factual."
}
```

Aggregate workflows such as multi-field generation should stay in the host
application. They may call the same Folio service repeatedly or wrap it in an
app-specific orchestration service, but Folio should still normalize each field
response to the schema above.

For controllers, the reusable part should be the service layer and response
contract. A thin host-app controller is still recommended when resource lookup,
abilities, or route shape are application-specific.

Suggested error codes:

- `feature_disabled`
- `prompt_missing`
- `record_not_ready`
- `missing_context`
- `invalid_context`
- `provider_timeout`
- `provider_rate_limited`
- `provider_model_unavailable`
- `provider_error`
- `response_invalid`
- `cost_limit_exceeded`

### 7.1 Provider Runtime Policy

Provider adapters must be deterministic at the boundary even when the provider
is not:

- Set explicit timeouts for connect/read/overall request duration.
- Abort editor requests on a bounded client timeout and show a retryable error
  instead of leaving the panel in loading indefinitely.
- Do not call providers from tests; use fake adapters, WebMock, or recorded
  cassettes outside unit tests.
- Retry at most idempotent transport failures, never schema-invalid content.
- Normalize rate limits separately from generic provider errors.
- Track latency, provider, model, requested/fallback model, warning code, error
  code, and suggestion count.
- Apply per-request and per-user cost guards before provider calls.
- Never include provider API keys, full prompts, record bodies, or suggestions
  in logs, exceptions, analytics, or background job arguments.

### 7.2 Frontend State Machine Invariants

The reusable panel should enforce these invariants:

- Only one local panel for a target field is active at a time.
- Opening a second local panel in the same form closes the first panel and clears
  its snapshot.
- Local field panels and host-app bulk workflows must not generate for the same
  field concurrently.
- Closing a panel or starting regeneration aborts the in-flight request where
  the browser supports it and ignores late responses otherwise.
- Manual field edits after accepting a suggestion clear selected-card state.
- Undo restores the snapshot captured at panel open, not the previous accepted
  suggestion.
- Regeneration replaces suggestions but does not refresh the undo snapshot.
- Copy never mutates the target field.
- Accept is the only action that writes generated text into the target field.

### 8. Tracking and Observability

AI assistance needs enough instrumentation to evaluate usefulness, cost, and
failure modes without storing editorial content in logs.

Recommended event names:

- `ai_suggestion_panel_opened`
- `ai_suggestion_generation_requested`
- `ai_suggestion_generation_succeeded`
- `ai_suggestion_generation_failed`
- `ai_suggestion_accepted`
- `ai_suggestion_copied`
- `ai_suggestion_undo_used`
- `ai_user_instruction_saved`

Recommended event properties:

- `site_id`
- `integration_key`
- `field_key`
- `provider`
- `model`
- `requested_model`
- `fallback_model`
- `suggestion_count`
- `latency_ms`
- `error_code`
- `warning_code`
- `record_class`

Do not track or log full default prompts, user instructions, record body, or
generated suggestion text unless a host app explicitly enables a separate,
privacy-reviewed audit mode.

### 9. Installation

Base integration should be documented as manual unless Folio explicitly ships a
generator.

Recommended installation steps:

1. Upgrade Folio and keep `:ai` in `Folio.enabled_packs` (enabled by default).
2. Run the AI pack migrations from `packs/ai/db/migrate`.
3. Configure provider credentials in the host app environment.
4. Register integrations and field metadata in a host-app initializer.
5. Optionally configure `folio_ai_provider_model_options` with curated labels
   and cost tiers for models the team is willing to expose in site settings.
6. Ensure the host app has a production cache store, ideally Redis-backed, so
   provider model catalogs can be cached for the configured TTL.
7. Add an AI form context wrapper to host-app forms that should support
   auto-attached standard fields.
8. Explicitly wire custom inputs, rich-text fields, and aggregate workflows via
   the public manual AI component API.
9. Add a thin host-app controller/route if the app wants a resource-specific API.
10. Enable the feature per site in the site settings tab.

No generator is required for the base architecture.

If Folio later ships a generator such as `rails g folio:ai:install`, it should
only scaffold the initializer and optional host-app stubs. The installation
guide must still document the manual steps above.

### 10. UI Verification Against Design

Shared Folio UI owns the reusable local panel pattern shown in the supplied
design exports for "AI Textarea or Input" and the local title suggestion states.
Host apps own any layout around the component, including title accordions and
bulk workflows.

The reusable component must preserve these design-level behaviours:

- The field action is a compact "AI suggestions" trigger with a sparkle mark.
- Opening the panel captures a temporary undo snapshot and starts generation.
- Loading shows three placeholder suggestion cards inside the panel.
- Missing content and provider failures render an inline panel error without
  mutating the target field.
- Loaded suggestions render as cards with copy and accept actions.
- Accepting a suggestion writes to the target field and highlights the accepted
  card with the green/teal selected state.
- Copying a suggestion never writes to the target field.
- Manual edits detach the selected-card state while keeping the panel open.
- Closing the panel clears the temporary undo snapshot and hides the undo action.
- Regeneration reuses the original snapshot and replaces cards in place.

Design verification for a host app should be done on the concrete form, because
placement depends on the app-owned SimpleForm wrapper or manual custom-field
wiring.

## Testing Scope

The Folio AI pack should cover:

- site-level config validation and visibility rules
- registry validation for unknown fields
- auto-attachment behavior for supported SimpleForm inputs
- prompt composition order
- provider selection fallback order
- user instruction persistence semantics
- TipTap plain-text helper behavior
- reusable panel states and undo lifecycle
- error normalization across providers

Host apps should cover:

- resource-specific authorization
- context builder correctness
- field wiring in concrete forms
- explicit wiring for custom inputs or aggregate workflows via the public manual
  AI component API
- app-owned aggregate workflows
- any structured rich-text output mapping
- analytics events emitted for the concrete form workflow

Minimum hardening coverage:

- Every availability gate has both visible and hidden UI tests.
- Every error code has a service/controller test and one UI state test where it
  affects the editor.
- Provider adapters are tested with success, timeout, rate limit, malformed
  response, empty response, and over-limit response cases.
- User instruction persistence is tested for save, preload, failed generation
  after save, and per-user/site/field isolation.
- Snapshot undo is tested for accept, repeated accept, regenerate, manual edit,
  close, and aborted/late responses.
- Test coverage thresholds must not be lowered; new branches introduced by this
  feature should be covered rather than excluded.

## Implementation Hardening Checklist

- Add any new AI ENV flags to `Folio::EnvFlags::FLAGS`.
- Keep global kill switch, site opt-in, prompt presence, field registration, and
  record eligibility as separate gates.
- Store prompt configuration separately from user instructions.
- Validate registry and site prompt configuration before rendering controls.
- Use current-state policy explicitly; do not silently generate from stale data.
- Normalize all provider responses before they reach controllers/components.
- Keep provider calls out of tests unless explicitly isolated.
- Make analytics best-effort and non-blocking for the editor workflow.
- Keep generated content out of logs, traces, events, and exception messages.
- Treat rich-text output as an explicit extension contract, not text with markup.

## Remaining Open Questions

- None in the Folio AI pack for the first implementation slice. Host
  applications still need to document their concrete context builders, rollout
  sites, prompt copy, custom fields, and aggregate workflows.
