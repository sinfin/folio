---
name: folio-testing
description: >-
  Folio Ruby/Rails testing conventions. Use when adding, changing, debugging,
  or reviewing tests, test helpers, factories/fixtures, mocks, stubs, or files
  under test/ and packs/*/test.
---

# Folio Testing

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

- Run the smallest relevant `bundle exec rails test ...` command first.
- For pack-owned changes, run that pack's tests and then use the `folio-pack`
  skill for Packwerk verification.
