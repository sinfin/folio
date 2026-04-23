# AI Prompts

## Status

Draft implementation plan for reusable AI prompt management in Folio.

This document intentionally stays product-agnostic. Client-specific prompt copy,
site names, and custom editorial workflows belong in host applications and in
runtime site settings, not in Folio core.

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
  channel-specific bulk generation into Folio core.
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

| Folio core owns | Host app owns |
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

- Put it in Folio when the behavior can be reused by another Folio application
  without knowing the concrete model class, form layout, editorial field names,
  distribution channels, or authorization rules.
- Keep it in the host app when it depends on a concrete resource, route shape,
  permission model, field taxonomy, aggregate workflow, rollout decision, prompt
  copy, or rich-text editor contract.
- If product acceptance criteria from a host app contradict this boundary,
  implement the reusable Folio contract first and leave the app-specific
  behavior to the host-app integration.

## V1 Decisions

These decisions are part of the implementation plan unless explicitly reopened.

- Folio ships the reusable service layer, provider adapters, persistence,
  response contract, and editor-side suggestion panel. Host applications keep
  thin resource-specific controllers for lookup, authorization, and route shape.
- Folio core v1 supports plain-text suggestions. Structured rich-text output is
  an extension point, not a v1 requirement. Host apps must not fake editor JSON
  until the target editor contract is known.
- The base installation is documented manual setup. A generator is optional
  later, but is not required for v1.
- AI never overwrites a field automatically. A suggestion affects a form field
  only after the editor accepts a suggestion card.
- User instructions are saved only by an explicit action in the AI panel. The
  same action also regenerates suggestions for the current panel context.
- Usage tracking is required in v1, but tracked events must not include full
  prompt text, record body, or generated suggestion content by default.

## Proposed Architecture

### 1. Feature Gating and Site Configuration

At the application level, Folio should default to AI being off. Runtime gates
must be layered, not collapsed into a single prompt check.

```ruby
Rails.application.config.folio_ai.enabled = false
```

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
  "default_model": "gpt-5.4-2026-03-05",
  "fields": {
    "content.title": {
      "enabled": true,
      "prompt": "Generate a concise headline...",
      "provider": "openai",
      "model": "gpt-5.4-2026-03-05"
    },
    "content.summary": {
      "enabled": true,
      "prompt": "Summarize the content in up to 400 characters..."
    }
  }
}
```

If any availability gate fails, no field-level AI UI is shown.

### 1.1 Storage Contract

Suggested migrations:

- `folio_sites.ai_settings` as `jsonb`, default `{}`, `null: false`.
- `folio_ai_user_instructions` with `user_id`, `site_id`, `integration_key`,
  `field_key`, `instructions`, timestamps, and a unique index across
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
- `instructions`
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

Docs-confirmed production model IDs:

- OpenAI: `gpt-5.4-2026-03-05` as the stable dated snapshot for GPT-5.4;
  `gpt-5.4` is the moving alias. The product target GPT-5.5 is not listed in
  the official OpenAI model docs yet, so it must stay configuration-only until
  OpenAI exposes an exact API model ID.
- Anthropic: `claude-opus-4-7` for Claude Opus 4.7.

The effective provider/model should resolve in this order:

1. Field override on the site
2. Site default
3. App default
4. Engine default

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
  "user_instructions": "Persisted value"
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
- `provider_error`
- `response_invalid`
- `cost_limit_exceeded`

### 7.1 Provider Runtime Policy

Provider adapters must be deterministic at the boundary even when the provider
is not:

- Set explicit timeouts for connect/read/overall request duration.
- Do not call providers from tests; use fake adapters, WebMock, or recorded
  cassettes outside unit tests.
- Retry at most idempotent transport failures, never schema-invalid content.
- Normalize rate limits separately from generic provider errors.
- Track latency, provider, model, error code, and suggestion count.
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
- `suggestion_count`
- `latency_ms`
- `error_code`
- `record_class`

Do not track or log full default prompts, user instructions, record body, or
generated suggestion text unless a host app explicitly enables a separate,
privacy-reviewed audit mode.

### 9. Installation

Base integration should be documented as manual unless Folio explicitly ships a
generator.

Recommended installation steps:

1. Upgrade Folio and run the AI-related migrations.
2. Configure provider credentials in the host app environment.
3. Register integrations and field metadata in a host-app initializer.
4. Add an AI form context wrapper to host-app forms that should support
   auto-attached standard fields.
5. Explicitly wire custom inputs, rich-text fields, and aggregate workflows via
   the public manual AI component API.
6. Add a thin host-app controller/route if the app wants a resource-specific API.
7. Enable the feature per site in the site settings tab.

No generator is required for the base architecture.

If Folio later ships a generator such as `rails g folio:ai:install`, it should
only scaffold the initializer and optional host-app stubs. The installation
guide must still document the manual steps above.

## Testing Scope

Folio core should cover:

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

- Should production keep the docs-confirmed OpenAI stable snapshot
  `gpt-5.4-2026-03-05`, or switch to GPT-5.5 only after OpenAI publishes an
  exact API model ID and the account has access?
