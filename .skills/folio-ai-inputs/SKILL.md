---
name: folio-ai-inputs
description: >-
  Wire Folio AI prompts and text suggestions to concrete Console inputs in a
  Folio-based host application. Use when registering AI promptable fields,
  adding folio_ai_form_context, auto-attaching standard SimpleForm inputs,
  manually rendering the AI suggestions component for custom inputs, building
  host-app AI suggestion endpoints, or preparing QA for this feature.
---

# Folio AI input wiring

Use this skill for host-app integration work around the reusable Folio AI pack.
The canonical contract is documented in `docs/features/ai_prompts.md`; read that
file before changing code.

## Boundary

- Keep generic behavior in `packs/ai`: registry, site prompt settings,
  availability gates, provider adapters, prompt composition, response
  normalization, user instructions, reusable component, Stimulus lifecycle,
  instrumentation, rate limits, and TipTap/plain-text helpers.
- Keep host-app behavior in the host app: concrete routes, authorization,
  record loading, context builder, promptable field list, form placement,
  aggregate workflows, rollout decisions, and prompt copy.
- Do not put site names, customer names, product-specific prompt text, or
  app-specific aggregate actions into Folio.

## Implementation Steps

1. Register an integration in a host-app initializer after Rails initialization:

   ```ruby
   Folio::Ai.register_integration(:content_editor,
                                  label: "Content editor",
                                  fields: [
                                    Folio::Ai::Field.new(key: :title,
                                                         label: "Title",
                                                         auto_attach: true,
                                                         input_types: %i[string],
                                                         character_limit: 120),
                                  ])
   ```

2. Use `auto_attach: true` only for standard SimpleForm `string` or `text`
   inputs that can receive the default Folio AI action inside an explicit form
   context.
3. Wrap eligible form sections with `folio_ai_form_context`, passing the
   integration key, endpoint, current record, and an explicit
   `current_state_policy`.
4. For custom inputs, composite components, rich-text wrappers, or unusual
   placement, render `Folio::Console::Ai::TextSuggestionsComponent` manually and
   pass `target_selector`, `integration_key`, `field_key`, `endpoint`,
   instructions, and character limit.
5. Implement a thin authenticated endpoint that includes
   `Folio::Console::Ai::SuggestionsControllerBase`. Override only record lookup,
   authorization, `folio_ai_context`, and `folio_ai_host_eligible?`.
6. Build context from safe plain text. For TipTap content prefer
   `Folio::Tiptap::PlainText.from_value(...)` or an existing stored plain-text
   projection before falling back to JSON traversal.
7. Configure provider models and optional cost labels through
   `folio_ai_provider_models` and `folio_ai_provider_model_options`. Let Folio
   use live provider catalogs when API credentials are present and keep fallback
   enabled for unavailable saved models.
8. Add Console site prompts for each site and field. Editor controls must stay
   hidden until the field has a non-blank site prompt and the record is eligible.
9. Cover visible and hidden gates, endpoint success and errors, context
   serialization, instruction persistence, timeout/rate-limit handling, model
   fallback warnings, and the full panel lifecycle in tests.

## UI Checklist

- AI action is inline with the input action area and uses the shared sparkle
  mark from `Folio::Ai::Icons`.
- Panel expands in normal DOM flow under the target input, not as a floating
  popup.
- Loading, missing context, provider error, variants, copy, accept, manual edit
  detach, ghost undo, close, save instructions, and regenerate states all match
  the reusable Folio component behavior.
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
