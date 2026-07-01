---
name: folio-testing
description: >-
  Folio and host-app testing conventions. Use when adding, changing,
  debugging, or reviewing tests, test helpers, factories/fixtures, mocks,
  stubs, ViewComponent tests, JavaScript behavior tests, integration/system
  coverage, or files under test/ and packs/*/test.
---

# Folio Testing

Use this skill for tests in the Folio gem and in host apps built on Folio.
Keep tests behavior-facing and close to the code they protect.

## Durable Rule

Never test JavaScript or asset-pipeline behavior by asserting that an asset
file contains a string or implementation snippet.

Instead, exercise the behavior through one of:
- rendered DOM assertions
- ViewComponent/component tests
- integration or system tests
- an actual JavaScript behavior test that runs the code path

## Test Shape

- Prefer behavior-facing assertions over implementation detail checks.
- Add or update focused tests near the changed component, model, controller, or
  pack.
- Use the smallest test type that proves the behavior; broaden to integration
  or system coverage when behavior crosses controllers, rendered HTML, browser
  interaction, or JavaScript execution.
- Avoid trivial existence tests that add noise without behavior coverage:
  method/constant existence, `respond_to?`, `defined?`, and similar assertions
  usually prove only implementation shape. Exercise the behavior instead.
- Avoid pinning private method names, asset contents, exact implementation
  snippets, or incidental markup that is not part of the user-facing contract.
- Do not test static presentation details that are always present and not part
  of conditional behavior, such as a fixed CSS utility class (`cell--compact`) or
  non-interactive styling option. Let the template/component code carry that.

## ViewComponents

- Assert rendered output (`render_inline`, `assert_selector`,
  `rendered_content`), not private methods or isolated helper calls.
- Prefer one `render_inline` per test; split variants into separate tests.
- Subclass the local component test base used by neighboring tests, commonly
  `Folio::ComponentTest` or `Folio::Console::ComponentTest`.

## Environment And Configuration

- Do not mutate `ENV` in tests for application behavior. Avoid save/delete/
  restore patterns around environment keys.
- If production behavior depends on `ENV`, expose a small app-owned accessor and
  stub that in tests. Prefer a method returning related values together when it
  makes tests cleaner.

  ```ruby
  Folio::Ai.stub(:provider_api_key_env_values, { openai: "secret" }) do
    # exercise behavior
  end
  ```

- For one-off flags, stub the value method directly:

  ```ruby
  Folio::Ai.stub(:env_disabled_value, "1") do
    # exercise disabled behavior
  end
  ```

- Tests that only read `ENV` to decide whether to run a live/VCR recording are
  acceptable, but they should not mutate `ENV`.

## Verification

- Run the smallest relevant focused test command first, usually
  `bundle exec rails test <path>` or a single test line.
- For pack-owned changes, run that pack's tests and then use the `folio-pack`
  skill for Packwerk verification.
- Run the formatter/linter appropriate to the edited files, such as
  `bundle exec rubocop --autocorrect-all <path>`, `npx standard --fix <path>`,
  or `slim-lint <path>`.
