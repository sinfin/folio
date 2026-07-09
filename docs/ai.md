# AI Suggestions

The AI pack adds console text suggestions for registered form fields. It is
intentionally small: a form snapshot, optional model-provided data, one provider
request, and MessageBus HTML fragments back to the editor.

## Enable The Pack

Enable the pack before Folio initializers run:

```ruby
Folio.enabled_packs = [:ai]
```

Run the pack migrations. They add `folio_sites.ai_settings` and
`folio_ai_user_instructions`.

Configure runtime defaults in an initializer:

```ruby
Folio::Ai.configure do |config|
  config.default_provider = Rails.env.development? ? :dummy : :openai
  config.text_suggestions_queue = :default
end
```

`FOLIO_AI_DISABLED` is a global kill switch. If the env key is present, AI is
disabled regardless of site settings.

## Providers

The development-only dummy provider is available as `:dummy` and only offers the
`dummy` model.

The OpenAI provider is available as `:openai` when
`FOLIO_AI_OPENAI_API_KEY` is present. `FOLIO_AI_OPENAI_MODELS` can contain a
comma-separated model list for the site settings select. If the list is blank,
the provider fallback model is used.

All Folio AI env keys use the `FOLIO_AI_` prefix.

## Register Records

Register each AI-enabled record class from the host app:

```ruby
Rails.application.config.after_initialize do
  Folio::Ai.register_record(record_class_name: "Article",
                            fields: [
                              { key: :perex, character_limit: 400 },
                              { key: :meta_title, character_limit: 120 },
                              { key: :meta_description, character_limit: 250 },
                            ],
                            groups: [
                              {
                                key: :meta,
                                label: "Meta fields",
                                fields: %i[meta_title meta_description],
                              },
                            ])
end
```

The record key is the model table name. Fields and groups store simple hashes:
`key`, optional `label`, optional `character_limit`, and group `fields`.
Registration exposes the field or group in site settings; it does not show
editor controls until the current site has it enabled with a nonblank prompt.

## Use In Forms

Use `ai: true` on registered SimpleForm inputs:

```slim
= f.input :perex, autosize: true,
                  character_counter: true,
                  ai: true
```

The record must be persisted, the site must have AI enabled, the field must be
registered, the field must be enabled with a nonblank site prompt, and an
available provider must be configured.

Grouped suggestions wrap normal AI inputs:

```slim
= render Folio::Ai::Console::TextSuggestionsGroupComponent.new(form: f,
                                                               key: :meta) do
  = f.input :meta_title, character_counter: true,
                         ai: true
  = f.input :meta_description, autosize: true,
                                character_counter: true,
                                ai: true
```

The group must be enabled with a nonblank site prompt under the group key. The
child inputs still own accepting, copying, undo, and final field updates.
When grouped child inputs use custom `input_html[:id]` values, pass matching
field metadata so grouped results target the rendered inputs:

```slim
= render Folio::Ai::Console::TextSuggestionsGroupComponent.new(form: f,
                                                               key: :meta,
                                                               fields: [
                                                                 { key: :meta_title, input_id: "custom_meta_title" },
                                                               ]) do
  = f.input :meta_title, ai: true,
                         input_html: { id: "custom_meta_title" }
```

Use `component_id` instead of `input_id` only when you need to pass the full AI
suggestion component id directly.

## Prompts And Data

Site admins edit provider, model, field prompts, group prompts, and field/group
enabled flags in the site console AI tab. User instructions are stored per
user, site, record key, and field or group key.

Provider prompts include the required site prompt plus the optional saved or
submitted user instruction. A user instruction never replaces the site prompt.

The form snapshot is the only automatic request data source. Before it reaches
the provider, Folio keeps only useful context roots:

- registered AI fields
- record columns with `string`, `text`, `json`, or `jsonb` types
- Tiptap fields, atom attributes, and attachment placement attributes

Framework fields, IDs, slugs, timestamps, destroyed nested records, and
password/token/secret-style keys are dropped. JSON values are sanitized
recursively.

A record can replace the root allowlist by defining:

```ruby
def folio_ai_form_snapshot_context_keys(default_keys:)
  default_keys + %w[custom_context]
end
```

Return the final top-level form snapshot keys to keep. Use this when a model
needs extra safe context, or when a normally allowed column should be excluded.

A record can also add structured context outside the form snapshot by defining:

```ruby
def folio_ai_additional_data(field_key:, form_snapshot:)
  {
    topic_names: topics.pluck(:name),
  }
end
```

Return a small hash that helps generate the requested field or group. Avoid
adding alternate data-source APIs for one-off use cases.

## Request Flow

1. `f.input ..., ai: true` renders the input controls.
2. Clicking the control posts one `key`, a `grouped` boolean, and the current
   form snapshot to `console_api_ai_text_suggestions_path`.
3. `Folio::Ai::TextSuggestionsJob` calls the selected provider.
4. The job publishes MessageBus payloads with rendered HTML fragments.
5. The frontend replaces suggestion HTML for the matching input components.

Single-field requests return three suggestions. Grouped requests return one
suggestion fragment for each field in the group plus the shared group controls
and instructions.

## Verify

Run the focused pack checks after changing AI code:

```bash
bundle exec rails test packs/ai/test
bundle exec rake app:packwerk:validate
bundle exec rake app:packwerk:check
```
