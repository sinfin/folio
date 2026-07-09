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

## Use In Forms

Use `ai: true` on registered SimpleForm inputs:

```slim
= f.input :perex, autosize: true,
                  character_counter: true,
                  ai: true
```

The record must be persisted, the site must have AI enabled, the field must be
registered, and an available provider must be configured.

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

The group uses its own prompt and saved user instruction under the group key.
The child inputs still own accepting, copying, undo, and final field updates.

## Prompts And Data

Site admins edit provider, model, field prompts, and group prompts in the site
console AI tab. User instructions are stored per user, site, record key, and
field or group key.

The form snapshot is the only automatic request data source. A record can add
structured context by defining:

```ruby
def folio_ai_additional_data(field_key:, form_snapshot:)
  {
    topic_names: topics.pluck(:name),
  }
end
```

Return a small hash that helps generate the requested field. Avoid adding
alternate data-source APIs for one-off use cases.

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
