---
name: folio-ai-inputs
description: >-
  Wire Folio AI prompts and text suggestions to concrete Console inputs in a
  Folio-based host application. Use when registering AI promptable fields,
  adding field-level SimpleForm `ai:` options or grouped generate-all wrappers,
  implementing model context methods for the centralized pack API, or preparing
  QA for this feature.
---

# Folio AI input wiring

Use this skill for host-app integration work around the reusable Folio AI pack.
The canonical technical contract is documented in `docs/ai.md`; read that file
before changing code. `docs/plans/ai_prompts_plan.md` is the original design
record.

## Boundary

- Keep generic behavior in `packs/ai` under `Folio::Ai::*`: registry, site
  prompt settings, availability gates, provider adapters, prompt composition,
  response normalization, user instructions, Stimulus lifecycle, API
  controllers, instrumentation, rate limits, and TipTap/plain-text helpers.
- Keep host-app behavior in the host app: model context methods, promptable
  field list, form placement, aggregate workflows, rollout decisions, and
  prompt copy.
- Do not put site names, customer names, product-specific prompt text, or
  app-specific aggregate actions into Folio.

## Implementation Steps

1. Enable the optional pack before engine initializers run:

   ```ruby
   Folio.enabled_packs = [:ai]
   ```

2. Configure the feature through `Folio::Ai.configure`:

   ```ruby
   Folio::Ai.configure do |config|
     config.enabled = true
     config.default_provider = :openai
     config.provider_models = {
       openai: "gpt-5.5",
       anthropic: "claude-opus-4-7",
     }
     config.provider_request_storage = false
   end
   ```

   The AI pack is disabled by default. OpenAI request storage remains disabled
   unless the host app explicitly opts in. Console AI API routes are mounted
   only when `Folio.pack_enabled?(:ai)`.

3. Register an integration in a host-app initializer after Rails initialization:

   ```ruby
   Folio::Ai.register_integration(record_class_name: "Article",
                                  fields: [
                                    Folio::Ai::Field.new(key: :title,
                                                         character_limit: 120),
                                  ])
   ```

4. Add `ai:` to each eligible standard SimpleForm `string` or `text` input.
   Folio infers eligibility from the registered record class attribute type:

   ```ruby
   f.input :title,
           ai: true
   ```

   `integration_key` defaults to the form object's table name and `field_key`
   defaults to the input attribute. `ai: true` uses both defaults. `ai: false`
   or a missing `ai:` option renders the normal input.
5. For one global "generate all" action, register a virtual field for the
   wrapper prompt/settings and wrap existing AI-enabled inputs with
   `Folio::Ai::Console::TextSuggestionsGroupComponent`:

   ```ruby
   Folio::Ai::Field.new(key: :all_ai_inputs,
                        label: "All AI inputs")
   ```

   ```slim
   = render(Folio::Ai::Console::TextSuggestionsGroupComponent.new(integration_key: :articles,
                                                                  field_key: :all_ai_inputs)) do
     = f.input :title, ai: true
     = f.input :perex, ai: true
   ```

   The wrapper component does not need a title prop. The wrapper virtual field
   owns shared prompt/provider/tracking/instructions and grouped-generation
   context. Child inputs are output targets for grouped generation; their own
   `ai: true` assistants, prompts, context, accept, stale-selection, and undo
   behavior still apply to standalone field-level generation.
6. `ai: true` uses `current_state_policy: :current_form_snapshot` by default.
   Use `:persisted_record` when generation should use saved server state.
7. Keep current-form filtering server-side. The Stimulus controller should keep
   sending all non-file successful form controls; `Folio::Ai::CurrentFormSnapshot`
   filters before the AI context is built.
8. Do not add per-integration context field configuration for the reusable pack
   snapshot. Use pack configuration for the generic top-level text roots and
   file-placement text keys.
9. Current-form snapshots keep only text-bearing context:
   configured top-level roots; all `record_class.folio_tiptap_fields` converted
   with `Folio::Tiptap::PlainText.from_value`; atom `data` leaves under
   `record_class.atom_keys`; and configured file-placement text leaves under
   `record_class.folio_attachment_keys`, including placement attributes nested
   inside atoms. Drop records marked with `_destroy` values of `1`, `"1"`,
   `true`, or `"true"`.
10. Keep custom inputs, composite components, rich-text wrappers, or unusual
   placement on explicit host-app wiring until their input ownership and undo
   contract is reviewed.
11. Model methods are optional extension points. Without them, Folio uses
   `{ current_form_snapshot: }` as context, requires a persisted record, falls
   through to the configured provider adapter, and resolves site from
   `folio_ai_site`, `site`, or `Folio::Current.site`.
12. Build context from safe plain text. For TipTap content prefer
   `Folio::Tiptap::PlainText.from_value(...)` or an existing stored plain-text
   projection before falling back to JSON traversal.
13. Configure provider models and optional cost labels through
   `Folio::Ai.provider_models` and `Folio::Ai.provider_model_options`. Let Folio
   use live provider catalogs when API credentials are present and keep fallback
   enabled for unavailable saved models.
14. Add Console site prompts for each site and field. For grouped wrappers,
   configure a prompt for the wrapper virtual field. Child field prompts are
   still needed for their standalone `ai: true` assistants, but grouped
   generation does not read child prompts or child contexts. Editor controls
   must stay hidden until the relevant field has a non-blank site prompt and the
   record is eligible.
15. Cover visible and hidden gates, HTML API success and errors, context
   serialization, instruction persistence, timeout/rate-limit handling, model
   fallback warnings, and the full panel lifecycle in tests.

## Pack Assets

- The AI pack exposes `folio_pack_ai.js` and `folio_pack_ai.css` through
  `Folio::Ai.pack_assets`.
- `folio_pack_ai.*` should include colocated component sidecars through
  Sprockets imports/requires.
- Optional pack Stimulus controllers register immediately when
  `window.Folio.Stimulus.register` exists, or listen once for
  `folio:stimulus-ready`.

## UI Checklist

- Initial form HTML renders only the spark action, undo action, and an empty
  `.form-group__custom-html` wrap. The API returns the full
  `Folio::Ai::Console::TextSuggestionsComponent` HTML into that wrap.
- Panel expands in normal DOM flow under the target input, not as a floating
  popup.
- Loading, missing context, provider error, variants, copy, accept, manual edit
  detach, ghost undo, close, save instructions, and regenerate states all match
  the reusable Folio component behavior.
- Grouped wrappers use one browser POST, one queued batch job, and one provider
  batch call from the wrapper prompt/context. Batch endpoints and MessageBus
  payloads return keyed rendered child panel HTML under `data.panels`; the
  wrapper distributes those panels back into existing field inputs by component
  id.
- Closing the panel clears the temporary undo snapshot; accepting a suggestion
  never auto-saves the record.
- Warnings from the backend are visible enough for editors/admins to notice
  configuration problems without blocking a valid fallback suggestion.

## Verification

Run the smallest relevant checks first, then the pack tests before handoff:

```bash
rvm 3.3.3 do bundle exec rails test packs/ai/test
rake app:packwerk:validate
rake app:packwerk:check
```
