# AI

This chapter describes the Folio AI suggestions pack. The pack provides
site-scoped prompt settings, provider adapters, user instruction persistence,
and a reusable Console UI for generating text suggestions for form inputs.

The original design plan is preserved in
[`docs/plans/ai_prompts_plan.md`](plans/ai_prompts_plan.md). This document is
the current technical reference for the implemented pack.

## TLDR

Enable the optional `:ai` pack, configure providers, register promptable fields,
add `ai:` to supported SimpleForm inputs, and configure prompts per site in
Console.

```ruby
# config/application.rb or another place loaded before Folio initializes
Folio.enabled_packs = [:ai]
```

```ruby
# config/initializers/folio_ai.rb
Folio::Ai.configure do |config|
  config.enabled = true
  config.default_provider = :openai
  config.provider_models = {
    openai: "gpt-5.4-mini",
    anthropic: "claude-opus-4-7",
  }
  config.provider_request_storage = false
end

Rails.application.config.after_initialize do
  Folio::Ai.register_integration(record_class_name: "Article",
                                 fields: [
                                   Folio::Ai::Field.new(key: :title,
                                                        character_limit: 120),
                                   Folio::Ai::Field.new(key: :perex,
                                                        character_limit: 400),
                                 ])
end
```

```slim
= f.input :title, ai: true
= f.input :perex, as: :text, ai: true
```

For the default flow, registered persisted records do not need model methods.
Folio sends the current form snapshot as context, uses the record's persisted
state for eligibility, and falls through to the configured provider adapter.

## Overview

Folio AI lives in `packs/ai` and is opt-in through `Folio.enabled_packs`. The
root Folio engine only provides pack loading, pack asset inclusion, shared
routes, and generic SimpleForm and Stimulus extension points. AI-specific
behavior stays under the `Folio::Ai` namespace. Once the pack is loaded, the
runtime `Folio::Ai.enabled` flag defaults to true unless host configuration or
`FOLIO_AI_DISABLED` turns it off.

The pack is designed around reusable text suggestions:

- host applications register integrations and fields
- admins enable AI and enter default prompts per site and field
- editors click an AI action beside an eligible input
- the browser requests loading-panel HTML from the centralized API
- the API loads and authorizes the record, prepares context, enqueues a job, and
  returns loading HTML through `render_component_json`
- the job calls the provider through `Folio::Ai::SuggestionGenerator` and
  publishes rendered suggestion-panel HTML over MessageBus
- accepting a suggestion writes to the form field but never saves the record

Host applications own product-specific decisions: which models and fields opt
in, prompt copy, context building, eligibility rules, rollout, and aggregate
workflows. The Folio AI pack owns the common registry, settings, availability
gates, provider boundary, prompt composition, response normalization,
instrumentation, HTML component, and input-level frontend state machine.

## Installation

### Enable the pack

Optional packs are loaded from `Folio.enabled_packs`. Enable the AI pack before
the Folio engine initializes:

```ruby
Folio.enabled_packs = [:ai]
```

The default is `[]`. When the pack is disabled, its runtime code, migrations,
views, locales, pack assets, and Console AI API routes are not part of the
enabled Folio feature set.
`Folio::Ai.enabled` is a separate runtime feature flag inside the loaded pack and
defaults to true.

### Run migrations

The AI pack ships two migrations:

- `folio_sites.ai_settings` stores site-level AI settings in JSONB
- `folio_ai_user_instructions` stores user/site/integration/field instructions

Run the pack migrations in the host application after enabling the pack.

### Configure the feature

Configure runtime behavior through `Folio::Ai.configure`:

```ruby
Folio::Ai.configure do |config|
  config.enabled = true
  config.default_provider = :openai
  config.provider_models = {
    openai: "gpt-5.4-mini",
    anthropic: "claude-opus-4-7",
  }
  config.provider_model_options = {
    openai: {
      "gpt-5.4-mini" => { label: "GPT-5.4 mini" },
      "gpt-5.5" => { label: "GPT-5.5", cost_tier: "premium" },
    },
  }
  config.model_fallback_enabled = true
  config.provider_request_timeout = 30
  config.client_request_timeout_ms = 45_000
  config.text_suggestions_queue = :default
  config.provider_request_storage = false
  config.max_prompt_chars = 80_000
  config.rate_limit = { limit: 30, period: 1.hour }
end
```

Important defaults:

- `enabled` is `true`
- `default_provider` is `:openai`
- provider defaults are `gpt-5.4-mini` and `claude-opus-4-7`
- `provider_model_options` includes built-in OpenAI options for `gpt-5.4-mini`
  and `gpt-5.5`
- `model_fallback_enabled` is `true`
- `provider_request_storage` is `false`
- `provider_request_timeout` is `30` seconds
- `client_request_timeout_ms` is `45_000`
- `text_suggestions_queue` is `:default`
- `max_prompt_chars` is `80_000`
- `rate_limit` is `nil`
- `current_form_snapshot_field_roots` controls generic top-level form roots
  allowed into current-form AI context
- `current_form_snapshot_file_placement_text_keys` controls file-placement
  text leaves allowed into current-form AI context

Set provider credentials with `FOLIO_AI_OPENAI_API_KEY` and/or
`FOLIO_AI_ANTHROPIC_API_KEY`.
`FOLIO_AI_DISABLED` is a global kill switch and makes `Folio::Ai.enabled?`
false even when configuration enables the feature.
Console settings and editor controls only expose eligible providers. OpenAI and
Anthropic are eligible when their `FOLIO_AI_*_API_KEY` is present; custom
providers configured in `provider_models` are eligible by default.

Set extra model select options with comma-separated provider ENV values such as
`FOLIO_AI_OPENAI_MODELS="gpt-5.4-nano,gpt-5.5-pro"` or
`FOLIO_AI_ANTHROPIC_MODELS="claude-opus-4-7,claude-sonnet-4-7"`.

OpenAI requests use the Responses API and include `store: false` unless the
host application explicitly sets `provider_request_storage = true`. Anthropic
requests use the Messages API with `anthropic-version: 2023-06-01`.

## Field Registry

Host applications register promptable fields after Rails initialization:

```ruby
Rails.application.config.after_initialize do
  Folio::Ai.register_integration(record_class_name: "Article",
                                 fields: [
                                   Folio::Ai::Field.new(key: :title,
                                                        character_limit: 120),
                                   Folio::Ai::Field.new(key: :perex,
                                                        character_limit: 400),
                                 ])
rescue ArgumentError => e
  raise unless e.message.include?("already registered")
end
```

`Folio::Ai::Field` accepts:

- `key`: canonical field key, stored as a string internally
- `label`: optional label override for Console site settings and panel titles;
  defaults to `record_class.human_attribute_name(key)`
- `response_format`: defaults to `:plain_text`
- `auto_attach`: defaults to `false`; retained field metadata only, because
  SimpleForm controls still require explicit `ai:` input options
- `character_limit`: optional limit used in settings hints and suggestion meta
- additional metadata keyword arguments for host-app use

`Folio::Ai.register_integration` requires `record_class_name`. The integration
key defaults to the record class table name, matching `ai: true`; pass `key:`
only when a model needs a non-default or additional integration key. The
integration label defaults to `record_class.model_name.human(count: 2)`.
The rendered SimpleForm input must match the registered attribute type:
`:string` columns attach to string inputs and `:text` columns attach to text
inputs. For translated models, localized columns returned by
`record_class.locale_columns(field_key)` are considered when inferring the input
type. Other attribute types are ignored.

The registry rejects blank or non-ActiveRecord class names, blank integration
keys, duplicate integrations, blank field keys, and duplicate field keys inside
one integration.

## Site Settings

When the AI pack is enabled, `Folio::Ai.enabled?` is true, and at least one
integration is registered, the Console site form gets an `ai_prompts` tab. The
tab renders `Folio::Ai::Console::SiteSettingsComponent`.

The settings are stored on `folio_sites.ai_settings`:

```json
{
  "enabled": true,
  "default_provider": "openai",
  "default_model": "gpt-5.4-mini",
  "integrations": {
    "articles": {
      "default_provider": "openai",
      "default_model": "gpt-5.4-mini",
      "fields": {
        "title": {
          "enabled": true,
          "prompt": "Write a concise title.",
          "provider": "openai",
          "model": "gpt-5.4-mini"
        }
      }
    }
  }
}
```

Site settings are validated while `Folio::Ai.enabled?` is true. Unknown
integrations, unknown fields, invalid nested structures, and unknown providers
are rejected. Blank prompts remain valid settings but keep that field
unavailable to editors. Saved model ids are not rejected by validation; the site
settings UI shows unavailable or unverified model notices from the model catalog.

### Availability gates

A field-level AI action is rendered only when all gates pass:

1. The AI pack is enabled and `FOLIO_AI_DISABLED` is not set.
2. The current site has AI enabled.
3. The integration and field are registered.
4. The site field setting is enabled.
5. The field has a non-blank default prompt.
6. The rendered input opts in with `ai:`.
7. The input is editable and has a supported SimpleForm input type.
8. The record is persisted.
9. Any optional model eligibility hook allows suggestions.

Direct API requests still use the same component rendering pipeline. Missing or
unauthorized records render `record_not_ready` immediately, and records blocked
by the host eligibility hook render `host_ineligible` immediately. Other
availability and provider failures are rendered into the MessageBus result with
public messages such as `prompt_missing`, `provider_timeout`,
`provider_rate_limited`, `provider_model_unavailable`, `response_invalid`,
`cost_limit_exceeded`, or `rate_limited`.

## SimpleForm Integration

The AI pack prepends `Folio::Ai::SimpleFormInputExtension` to
`SimpleForm::Inputs::Base`. Standard `string` and `text` inputs can opt in with
the `ai:` option:

```slim
= f.input :title,
          ai: true

= f.input :perex,
          as: :text,
          ai: { integration_key: :articles,
                suggestion_count: 3,
                show_meta: true }
```

`ai: true` infers:

- `integration_key` from the form object's table name
- `field_key` from the input attribute
- `record` from the form object
- `site` from `Folio::Current.site`
- `current_state_policy` as `:current_form_snapshot`

`ai: false` or a missing `ai:` option renders the normal input.

Hash options may override `record`, `site`, `integration_key`, `field_key`,
`current_state_policy`, `suggestion_count`, `show_meta`, `request_timeout_ms`,
and the button/loading/error labels used by the input wrapper. Unsupported
`current_state_policy` values prevent attachment. `suggestion_count` defaults to
3 and is capped at 10 by `Folio::Ai::TextSuggestionsJob`.

When attachment succeeds, the input wrapper receives:

- `form-group--with-ai-text-suggestions`
- `data-controller="f-ai-input"`
- the target input data attribute
- an AI action button
- a hidden undo button
- an empty custom HTML target for the loaded suggestion panel

AI controls are not attached on new records, disabled inputs, readonly inputs,
unsupported input types, unregistered fields, disabled sites, missing prompts,
or host-ineligible records.

### Current state policy

`current_state_policy` controls what context the browser sends:

- `:current_form_snapshot` is the default. It sends the current successful form
  control values as JSON while the backend still authorizes the persisted record
- `:persisted_record` sends no form snapshot and expects the model context to
  use saved server state

The browser snapshot ignores file inputs and otherwise sends successful form
controls without client-side field filtering. Repeated field names are sent as
arrays. The controller filters the payload server-side with
`Folio::Ai::CurrentFormSnapshot`, keeps only string/numeric/boolean scalar
values, stringifies numbers and booleans, and limits the snapshot to 200 fields
before passing it as the text suggestion job argument.

The server-side snapshot filter keeps only text-bearing context:

- configured top-level roots from `Folio::Ai.current_form_snapshot_field_roots`
- all fields declared by `record_class.folio_tiptap_fields`, converted with
  `Folio::Tiptap::PlainText.from_value`
- atom `data` leaves under roots derived from `record_class.atom_keys`
- configured file placement text leaves from
  `Folio::Ai.current_form_snapshot_file_placement_text_keys`, both for normal
  placement roots derived from `record_class.folio_attachment_keys` and for
  placement attributes nested inside atoms

Nested atom or file placement records marked with `_destroy` values of `1`,
`"1"`, `true`, or `"true"` are omitted. Unknown roots, IDs, file IDs, positions,
types, submit controls, authenticity tokens, slugs, and unrelated nested
associations are dropped.

## Model Contract

The API controller loads and authorizes records model-agnostically before
queueing the job. A registered persisted record can use AI suggestions without
defining model methods. The default behavior is:

- context is `{ current_form_snapshot: current_form_snapshot }`
- eligibility is `record.persisted?`
- provider adapter falls through to the configured Folio provider
- site resolves from `folio_ai_site`, then `site`, then `Folio::Current.site`

If no authorized persisted record is found, the controller renders the same
panel with a localized `record_not_ready` status immediately instead of
enqueueing a background job. If the record is found but the host eligibility
hook rejects it, the controller likewise renders `host_ineligible` immediately.

Host applications can override the defaults with model methods when they need
product-specific context, stricter eligibility, a custom provider adapter, or a
custom site association.

```ruby
class Article < ApplicationRecord
  def folio_ai_context(field_key:, current_form_snapshot:)
    Articles::AiContextBuilder.new(article: self,
                                   field_key:,
                                   current_form_snapshot:).call
  end

  def folio_ai_suggestions_eligible?(field_key:, current_form_snapshot:)
    persisted? && body_text.present?
  end

  def folio_ai_provider_adapter
    MyApp::Ai::DemoProviderAdapter.new if Rails.env.development?
  end

  def folio_ai_site
    site
  end
end
```

Optional methods:

- `folio_ai_context(field_key:, current_form_snapshot:)`
- `folio_ai_suggestions_eligible?(field_key:, current_form_snapshot:)`
- `folio_ai_provider_adapter`
- `folio_ai_site`

The context can be a hash or string. Hash contexts are formatted as pretty JSON
inside the prompt. Host applications should keep context builders explicit and
avoid sending raw rich-text editor JSON unless the app owns a reviewed mapper.
Because generation runs in a background job, `folio_ai_provider_adapter` is only
serialized as a class name. The job instantiates that class with `.new`, so
custom adapters should be instantiable without record-local state.

For persisted TipTap content in custom context builders, prefer the reusable
plain-text helper:

```ruby
Folio::Tiptap::PlainText.from_value(record.tiptap_content)
```

## API Flow

When the AI pack is enabled, the shared route is mounted in the Folio Console
API:

```text
POST /console/api/ai_text_suggestions/text_suggestions
POST /console/api/ai_text_suggestions/instructions
```

Both actions are handled by
`Folio::Ai::Console::Api::TextSuggestionsController`. The routes are not mounted
when `Folio.pack_enabled?(:ai)` is false.

The request contains the record class, record id, integration key, field key,
component id, display options, suggestion count, the MessageBus client id, and
optionally instructions or a current form snapshot.

```json
{
  "klass": "Article",
  "id": "123",
  "integration_key": "articles",
  "field_key": "perex",
  "component_id": "folio_ai_text_suggestions_article_perex",
  "suggestion_count": 3,
  "show_meta": true,
  "message_bus_client_id": "message-bus-client",
  "instructions": "Use a calmer voice.",
  "current_form_snapshot_json": "{\"article[title]\":\"Draft title\"}"
}
```

The controller:

1. Requires `message_bus_client_id`.
2. Resolves `klass` through `safe_constantize` and requires an
   `ActiveRecord::Base` subclass.
3. Starts from `record_class.accessible_by(Folio::Current.ability)`.
4. Filters by the current site when the model supports `by_site`.
5. Rejects records from another site.
6. Persists editor instructions synchronously for the instructions endpoint when
   a record was found.
7. Filters the optional current form snapshot.
8. Resolves model eligibility and renders `record_not_ready` or
   `host_ineligible` immediately when the record cannot generate suggestions.
9. Resolves model-provided context, field label, AI site, and any serializable
   provider adapter class.
10. Generates a request id.
11. Enqueues `Folio::Ai::TextSuggestionsJob`.
12. Renders `Folio::Ai::Console::TextSuggestionsComponent` in a loading state.
13. Wraps the loading HTML with `render_component_json`.

For queued requests, the initial JSON response has a string `data` key
containing loading HTML, and a `meta.request_id` value used to match the
MessageBus result:

```json
{
  "data": "<div class=\"f-ai-c-text-suggestions\">...</div>",
  "meta": {
    "request_id": "request-id"
  }
}
```

The API does not wait for the provider and does not return raw suggestion JSON
to the browser.

Immediate `record_not_ready` and `host_ineligible` responses omit
`meta.request_id`; the browser treats the returned component HTML as the final
panel state and does not wait for MessageBus.

The prepared context and request metadata are passed directly as ActiveJob
arguments. Folio does not persist them separately; host queue backends such as
Sidekiq may still expose job arguments in operational tooling. Record class/id
and CanCanCan authorization stay in the controller and are not job inputs.

`Folio::Ai::TextSuggestionsJob` runs on `Folio::Ai.text_suggestions_queue`.
The job does not use `Folio::Current`; it only loads the already selected
`user` and AI `site` by id, then:

1. Calls `Folio::Ai::SuggestionGenerator` with the prepared context and
   eligibility.
2. Renders `Folio::Ai::Console::TextSuggestionsComponent`.
3. Publishes rendered HTML to `Folio::MESSAGE_BUS_CHANNEL` for the original
   MessageBus client id.

The MessageBus payload is:

```json
{
  "type": "Folio::Ai::TextSuggestionsJob",
  "data": {
    "request_id": "request-id",
    "component_id": "folio_ai_text_suggestions_article_perex",
    "html": "<div class=\"f-ai-c-text-suggestions\">...</div>"
  }
}
```

## Suggestion Pipeline

`Folio::Ai::SuggestionGenerator` coordinates server-side generation:

1. Check `Folio::Ai::Availability`.
2. Load `Folio::Ai::UserInstruction`, or persist it only when the generator is
   called with `persist_instructions: true`.
3. Resolve provider and model through `Folio::Ai::ProviderConfig`.
4. Compose the prompt with `Folio::Ai::PromptComposer`.
5. Run `Folio::Ai::RequestGuard` for prompt length and rate limit.
6. Call the provider adapter.
7. Normalize output through `Folio::Ai::ResponseNormalizer`.
8. Track sanitized success, failure, and fallback events.

Prompt composition is deterministic:

1. Site default prompt.
2. Stored or submitted user instructions.
3. Host-app context.

The default prompt is mandatory. The Console API persists user instructions per
user/site/integration/field when the editor uses the save/regenerate action,
then passes the effective instruction to the job with `persist_instructions:
false`.

## Providers and Models

Built-in adapters live under `Folio::Ai::Providers`:

- `Folio::Ai::Providers::OpenAi`
- `Folio::Ai::Providers::Anthropic`

Adapters build provider-specific HTTP requests, set bounded timeouts, normalize
provider failures, and pass response text through the shared normalizer. Rate
limits become `provider_rate_limited`, timeouts become `provider_timeout`, and
missing models become `provider_model_unavailable`. The OpenAI adapter posts to
`/v1/responses`; the Anthropic adapter posts to `/v1/messages`.

Host-provided adapters must respond to
`generate_suggestions(prompt:, field:, suggestion_count:)` and return
`Folio::Ai::Suggestion` objects. Adapters that call external providers can use
`Folio::Ai::ResponseNormalizer` before returning.

Provider model selection is resolved in this order:

1. Field provider/model.
2. Integration provider/model.
3. Site provider/model.
4. Application default provider/model.

When a provider override is present without a model override, Folio uses that
provider's configured default model. This prevents an OpenAI model from being
inherited accidentally for an Anthropic provider override.

`Folio::Ai::ModelCatalog` builds Console model select options without calling
provider APIs. Options come from the provider default model,
`FOLIO_AI_<PROVIDER>_MODELS`, configured `provider_model_options`, and any saved
selected model that is no longer listed. Configured `provider_model_options`
also supply optional labels and cost tiers.
When no provider is eligible, Console site settings keep AI disabled and hide
provider/model/prompt settings.

If generation fails because the selected model is unavailable and
`model_fallback_enabled?` is true, Folio retries once with the provider default
model. Successful fallback responses include a warning in the rendered panel.

## Frontend Behavior

The pack exposes `folio_pack_ai.js` and `folio_pack_ai.css`. The Console layout
includes these logical assets through `Folio.enabled_pack_assets(type)` when the
pack is enabled.

`folio_pack_ai.js` registers:

- `f-ai-input` for the input wrapper and API lifecycle
- `f-ai-c-text-suggestions` for the rendered suggestions component

Optional pack controllers register immediately when `window.Folio.Stimulus`
exists or wait for the `folio:stimulus-ready` event from the root Stimulus
bootstrap.

### Input controller

`f-ai-input` owns the field session:

- opens only one AI panel on the page at a time
- captures an undo snapshot when opened
- sends POST for initial suggestions
- sends POST with instructions for saving custom instructions and regeneration
- optionally serializes a current form snapshot
- includes the current `window.MessageBus.clientId`
- aborts in-flight requests on close or regenerate
- enforces the client request timeout
- closes on outside click or Escape
- injects returned loading component HTML into the custom HTML target
- stores `meta.request_id` from the loading response
- waits for a matching `Folio::Ai::TextSuggestionsJob` MessageBus payload
- replaces the loading component with the final rendered component HTML
- preserves in-progress instructions textarea edits while replacing panel HTML
- writes accepted suggestions into the input
- dispatches `input`, `change`, and `folioConsoleCustomChange` with autosave
  suppressed for accepted suggestions
- restores the opening snapshot on undo
- clears selected-card state when the user manually edits the field

Accepting a suggestion changes only the form field. Selecting a suggestion does
not trigger Console autosave; the record is saved only when the editor submits
the form.

### Suggestions component

`Folio::Ai::Console::TextSuggestionsComponent` renders the panel HTML:

- close button
- status area for errors and warnings
- suggestion cards
- copy buttons
- accept buttons
- optional meta such as tone and character count
- instructions textarea
- save/regenerate button
- loading suggestion placeholders

`f-ai-c-text-suggestions` dispatches component events back to `f-ai-input` for
close, regenerate, and accept. Copying uses the shared Console clipboard
component and never mutates the target field.

## Tracking and Safety

`Folio::Ai.track` instruments `ActiveSupport::Notifications` events under
`folio.ai.*`. Payloads are allow-listed to operational metadata:

- site and user ids
- integration and field keys
- provider and model
- requested and fallback model
- suggestion count
- latency
- error and warning codes
- record class

Prompts, user instructions, record bodies, provider API keys, and generated
suggestions are not included in tracking payloads by default.

## Dummy App

The dummy app enables the AI pack in development and test:

```ruby
Folio.enabled_packs = [:ai] if Rails.env.development? || Rails.env.test?
```

`test/dummy/config/initializers/folio_ai.rb` enables the runtime flag and
registers `dummy_blog_articles` in development. Pack tests reset and register AI
fields explicitly. The dummy AI code lives in `test/dummy/packs/ai` and adds
model hooks to `Dummy::Blog::Article` through a pack railtie.

The dummy provider adapter returns deterministic suggestions and does not call
OpenAI or Anthropic. This keeps local UI verification possible without provider
credentials.

The dummy blog article form uses:

```slim
= f.input :title, ai: true
= f.input :perex, ai: true
= f.input :meta_title, ai: true
= f.input :meta_description, ai: true
```

Manual check:

1. Start the dummy app in development.
2. Open Console site settings and enable AI prompts for the current site.
3. Fill non-blank prompts for the dummy blog article fields.
4. Open an existing dummy blog article with a title or perex.
5. Click the AI action beside a configured field.
6. Verify loading, variants, copy, accept, undo, close, instructions, and
   regenerate.

## Testing

Run the focused AI pack tests when changing the pack:

```bash
bundle exec rails test packs/ai/test
```

Run Packwerk checks when changing pack boundaries:

```bash
bundle exec rake app:packwerk:validate
bundle exec rake app:packwerk:check
```

Useful coverage areas:

- registry validation
- site settings validation and visibility
- availability gates
- SimpleForm attachment and hidden cases
- centralized API loading response and job enqueueing
- text suggestion job success and error broadcasts
- model context and current form snapshot handling
- provider requests, failures, and response normalization
- model catalog and fallback warnings
- user instruction persistence
- frontend open, abort, timeout, accept, copy, undo, close, and regenerate
