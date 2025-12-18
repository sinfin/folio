# Testing

This chapter describes the testing setup shipped with the Folio Rails Engine and how to write and run tests for your application.

---

## Test Framework & Tools

Folio uses the default **Minitest** framework that ships with Rails, extended with several helpful gems:

| Gem | Purpose |
|-----|---------|
| `capybara` | System/feature tests (browser automation) |
| `capybara-minitest` | Integrates Capybara with Minitest assertions |
| `factory_bot` | Factories for test data |
| `vcr` + `webmock` | Record and stub external HTTP requests |

You can find the core setup in `test/test_helper_base.rb`.

---

## Test Helpers & Base Classes

The engine defines several base classes that you can inherit from:

| Class | Inherits | Use case |
|-------|----------|----------|
| `ActiveSupport::TestCase` | Minitest unit test | Model/unit tests (includes FactoryBot) |
| `Cell::TestCase` |  | Tests for legacy Trailblazer Cells |
| `ActionDispatch::IntegrationTest` | | Controller & request tests (Devise helpers included) |
| `Folio::CapybaraTest` | IntegrationTest | Full-stack browser tests with Capybara |
| `Folio::ComponentTest` | `ViewComponent::TestCase` | Tests for ViewComponents |
| `Folio::BaseControllerTest` | `ActionDispatch::IntegrationTest` | Adds site and user handling |
| `Folio::Console::BaseControllerTest` | `Folio::BaseControllerTest` | Creates and signs in a superadmin user |

Each base class automatically:
- Resets `Folio::Current` context (site/user)
- Includes `FactoryBot::Syntax::Methods`
- Provides helpers from `test/support/`

---

## Factories

Factories live in `test/factories.rb` and are loaded via FactoryBot. When you generate new models, remember to add corresponding factories.

```ruby
factory :my_application_list, class: "MyApplication::List" do
  title { "hello" }
  published { true }
end
```

---

## Running Tests

```sh
rails test           # run all tests
```

Parallel testing is enabled by default (`parallelize` in `test_helper_base.rb`).

To run tests sequentially (useful for debugging):

```sh
PARALLEL_WORKERS=1 rails test
```

---

## Troubleshooting

### Tests Hang Indefinitely in Parallel Mode

If tests hang during parallel execution with errors like:

```
DRb::DRbConnError: drbunix:/tmp/druby12345.0 - No such file or directory
```

This is usually caused by **stale database connections** from a previous interrupted test run. The "idle in transaction" connections hold locks that block parallel test workers from setting up their test databases.

**Solution:** Terminate stale connections before running tests:

```sh
psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname LIKE 'your_app_test%' AND state = 'idle in transaction';" your_app_test
```

Replace `your_app_test` with your actual test database name (e.g., `folio_test`).

**Prevention:** Always allow test runs to complete gracefully. If you must interrupt (`Ctrl+C`), the cleanup should handle connections, but occasionally stale connections remain.

---

## Best Practices

- Use **factories** instead of fixtures for clearer intent.
- Use the provided base classes so `Folio::Current` is managed for you.
- Record external API calls with **VCR** to keep tests deterministic.
- Prefer **Component tests** for ViewComponent logic and rendering.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Configuration](configuration.md)
- [Next: HTML Sanitization →](sanitization.md)

---

*This testing overview will be updated as the documentation evolves.*
