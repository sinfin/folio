# AI

This chapter describes the Folio AI suggestions pack. The pack provides
site-scoped prompt settings, provider adapters, user instruction persistence,
and a reusable Console UI for generating text suggestions for form inputs.

The original design plan is preserved in
[`docs/plans/ai_prompts_plan.md`](plans/ai_prompts_plan.md). This document is
the current technical reference for the implemented pack.

## TLDR

Enable the optional `:ai` pack, configure providers, register promptable fields,
implement the model context methods, add `ai:` to supported SimpleForm inputs,
and configure prompts per site in Console.

```ruby
# config/application.rb or another place loaded before Folio initializes
Folio.enabled_packs = [:ai]
```

```ruby
# config/initializers/folio_ai.rb
Folio::Ai.configure do |config|
  config.enabled = ENV["FOLIO_AI_ENABLED"].present?
  config.default_provider = :openai
  config.provider_models = {
    openai: "gpt-5.5",
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

```ruby
class Article < ApplicationRecord
  def folio_ai_context(field_key:, current_form_snapshot:)
    {
      title:,
      perex:,
      current_form_snapshot: current_form_snapshot.presence,
    }.compact
  end

  def folio_ai_suggestions_eligible?(field_key:, current_form_snapshot:)
    persisted? && [title, perex].any?(&:present?)
  end
end
```

```slim
= f.input :title, ai: true
= f.input :perex, as: :text, ai: true
```

## Overview

Folio AI lives in `packs/ai` and is disabled by default. The root Folio engine
only provides pack loading, pack asset inclusion, shared routes, and generic
SimpleForm and Stimulus extension points. AI-specific behavior stays under the
`Folio::Ai` namespace.

The pack is designed around reusable text suggestions:

- host applications register integrations and fields
- admins enable AI and enter default prompts per site and field
- editors click an AI action beside an eligible input
- the browser requests rendered suggestion-panel HTML from the centralized API
- the API loads and authorizes the record, asks the model for context, calls the
  provider, and returns `render_component_json`
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
views, locales, and pack assets are not part of the enabled Folio feature set.

### Run migrations

The AI pack ships two migrations:

- `folio_sites.ai_settings` stores site-level AI settings in JSONB
- `folio_ai_user_instructions` stores user/site/integration/field instructions

Run the pack migrations in the host application after enabling the pack.

### Configure the feature

Configure runtime behavior through `Folio::Ai.configure`:

```ruby
Folio::Ai.configure do |config|
  config.enabled = ENV["FOLIO_AI_ENABLED"].present?
  config.default_provider = :openai
  config.provider_models = {
    openai: "gpt-5.5",
    anthropic: "claude-opus-4-7",
  }
  config.provider_model_options = {
    openai: {
      "gpt-5.5" => { label: "GPT-5.5", cost_tier: "premium", default: true },
    },
  }
  config.model_fallback_enabled = true
  config.model_catalog_cache_ttl = 1.hour
  config.provider_request_timeout = 30
  config.client_request_timeout_ms = 45_000
  config.provider_request_storage = false
  config.max_prompt_chars = 80_000
  config.rate_limit = { limit: 30, period: 1.hour }
end
```

Important defaults:

- `enabled` is `false`
- `default_provider` is `:openai`
- provider defaults are `gpt-5.5` and `claude-opus-4-7`
- `model_fallback_enabled` is `true`
- `provider_request_storage` is `false`
- `provider_request_timeout` is `30` seconds
- `client_request_timeout_ms` is `45_000`
- `max_prompt_chars` is `80_000`
- `rate_limit` is `nil`

Set provider credentials with `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY`.
`FOLIO_AI_DISABLED` is a global kill switch and makes `Folio::Ai.enabled?`
false even when configuration enables the feature.

OpenAI requests use the Responses API and include `store: false` unless the
host application explicitly sets `provider_request_storage = true`.

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
- `auto_attach`: retained field metadata; SimpleForm controls still require
  explicit `ai:` input options
- `character_limit`: optional limit used in settings hints and suggestion meta
- additional metadata keyword arguments for host-app use

`Folio::Ai.register_integration` requires `record_class_name`. The integration
key defaults to the record class table name, matching `ai: true`; pass `key:`
only when a model needs a non-default or additional integration key. The
integration label defaults to `record_class.model_name.human(count: 2)`.
The rendered SimpleForm input must match the registered attribute type:
`:string` columns attach to string inputs and `:text` columns attach to text
inputs. Other attribute types are ignored.

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
  "default_model": "gpt-5.5",
  "integrations": {
    "articles": {
      "default_provider": "openai",
      "default_model": "gpt-5.5",
      "fields": {
        "title": {
          "enabled": true,
          "prompt": "Write a concise title.",
          "provider": "openai",
          "model": "gpt-5.5"
        }
      }
    }
  }
}
```

Site settings are validated while `Folio::Ai.enabled?` is true. Unknown
integrations, unknown fields, invalid nested structures, and unknown providers
are rejected. Blank prompts remain valid settings but keep that field
unavailable to editors.

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
9. The model eligibility hook allows suggestions.

Direct API requests still return rendered component HTML for failures, using
public error messages such as `prompt_missing`, `record_not_ready`,
`host_ineligible`, `provider_timeout`, or `rate_limited`.

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
                current_state_policy: :current_form_snapshot,
                suggestion_count: 3,
                show_meta: true }
```

`ai: true` infers:

- `integration_key` from the form object's table name
- `field_key` from the input attribute
- `record` from the form object
- `site` from `Folio::Current.site`
- `current_state_policy` as `:persisted_record`

`ai: false` or a missing `ai:` option renders the normal input.

When attachment succeeds, the input wrapper receives:

- `form-group--with-ai-text-suggestions`
- `data-controller="f-ai-input"`
- the target input data attribute
- an AI action button
- a hidden undo button
- an empty custom HTML target for the loaded suggestion panel

The field remains hidden on new records, disabled inputs, readonly inputs,
unsupported input types, unregistered fields, disabled sites, missing prompts,
or host-ineligible records.

### Current state policy

`current_state_policy` controls what context the browser sends:

- `:persisted_record` sends no form snapshot and expects the model context to
  use saved server state
- `:current_form_snapshot` sends the current successful form control values as
  JSON while the backend still authorizes the persisted record

The snapshot ignores file inputs. Repeated field names are sent as arrays. The
controller keeps string values, stringifies numbers and booleans, and limits the
snapshot to 200 fields before passing it to the model context method.

## Model Contract

The centralized endpoint loads and authorizes records model-agnostically, then
delegates host-specific context to the record.

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

Required method:

- `folio_ai_context(field_key:, current_form_snapshot:)`

Optional methods:

- `folio_ai_suggestions_eligible?(field_key:, current_form_snapshot:)`
- `folio_ai_provider_adapter`
- `folio_ai_site`

The context can be a hash or string. Hash contexts are formatted as pretty JSON
inside the prompt. Host applications should keep context builders explicit and
avoid sending raw rich-text editor JSON unless the app owns a reviewed mapper.

For TipTap content, prefer the reusable plain-text helper:

```ruby
Folio::Tiptap::PlainText.from_value(record.tiptap_content)
```

## API Flow

The shared route is mounted in the Folio Console API:

```text
GET  /console/api/ai_text_suggestions
POST /console/api/ai_text_suggestions/instructions
```

Both actions are handled by
`Folio::Ai::Console::Api::TextSuggestionsController`.

The request contains the record class, record id, integration key, field key,
component id, display options, suggestion count, and optionally instructions or
a current form snapshot.

```json
{
  "klass": "Article",
  "id": "123",
  "integration_key": "articles",
  "field_key": "perex",
  "component_id": "folio_ai_text_suggestions_article_perex",
  "suggestion_count": 3,
  "instructions": "Use a calmer voice.",
  "current_form_snapshot_json": "{\"article[title]\":\"Draft title\"}"
}
```

The controller:

1. Resolves `klass` through `safe_constantize` and requires an
   `ActiveRecord::Base` subclass.
2. Starts from `record_class.accessible_by(Folio::Current.ability)`.
3. Filters by `Folio::Current.site` when the model supports `by_site`.
4. Rejects records from another site.
5. Calls model context and eligibility hooks.
6. Calls `Folio::Ai::SuggestionGenerator`.
7. Renders `Folio::Ai::Console::TextSuggestionsComponent`.
8. Wraps the HTML with `render_component_json`.

The JSON response therefore has a string `data` key containing HTML:

```json
{
  "data": "<div class=\"f-ai-c-text-suggestions\">...</div>"
}
```

The API does not return raw suggestion JSON to the browser.

## Suggestion Pipeline

`Folio::Ai::SuggestionGenerator` coordinates server-side generation:

1. Check `Folio::Ai::Availability`.
2. Load or persist `Folio::Ai::UserInstruction`.
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

The default prompt is mandatory. User instructions are persisted per
user/site/integration/field only when the editor uses the regenerate/save action.

## Providers and Models

Built-in adapters live under `Folio::Ai::Providers`:

- `Folio::Ai::Providers::OpenAi`
- `Folio::Ai::Providers::Anthropic`

Adapters build provider-specific HTTP requests, set bounded timeouts, normalize
provider failures, and pass response text through the shared normalizer. Rate
limits become `provider_rate_limited`, timeouts become `provider_timeout`, and
missing models become `provider_model_unavailable`.

Provider model selection is resolved in this order:

1. Field provider/model.
2. Integration provider/model.
3. Site provider/model.
4. Application default provider/model.

When a provider override is present without a model override, Folio uses that
provider's configured default model. This prevents an OpenAI model from being
inherited accidentally for an Anthropic provider override.

`Folio::Ai::ModelCatalog` fetches live model lists through provider APIs when
credentials are present and caches them in `Rails.cache` for
`model_catalog_cache_ttl`. Configured `provider_model_options` supply labels,
cost tiers, and fallback options when live catalogs cannot be verified. Saved
models that are no longer available stay visible in site settings as
unavailable.

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

- opens only one AI panel in the form at a time
- captures an undo snapshot when opened
- sends GET for initial suggestions
- sends POST with instructions for regenerate/save
- optionally serializes a current form snapshot
- aborts in-flight requests on close or regenerate
- enforces the client request timeout
- injects returned component HTML into the custom HTML target
- writes accepted suggestions into the input
- dispatches `input`, `change`, and `folioConsoleCustomChange`
- restores the opening snapshot on undo
- clears selected-card state when the user manually edits the field

Accepting a suggestion changes only the form field. The record is saved only
when the editor submits the form.

### Suggestions component

`Folio::Ai::Console::TextSuggestionsComponent` renders the panel HTML:

- close button
- status area for errors and warnings
- suggestion cards
- copy buttons
- accept buttons
- optional meta such as tone and character count
- instructions textarea
- regenerate/save button
- loader

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

`test/dummy/config/initializers/folio_ai.rb` enables AI in development and
registers `dummy_blog_articles`. The dummy AI code lives in
`test/dummy/packs/ai` and adds model hooks to `Dummy::Blog::Article` through a
pack railtie.

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
4. Open an existing dummy blog article.
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
- centralized API success and error rendering
- model context and current form snapshot handling
- provider requests, failures, and response normalization
- model catalog and fallback warnings
- user instruction persistence
- frontend open, abort, timeout, accept, copy, undo, close, and regenerate
