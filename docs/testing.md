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
| `view_component-test` | Test helpers for ViewComponent |

You can find the core setup in `test/test_helper_base.rb`.

---

## Test Helpers & Base Classes

The engine defines several base classes that you can inherit from:

| Class | Inherits | Use case |
|-------|----------|----------|
| `ActiveSupport::TestCase` | Minitest unit test | Model/unit tests (includes FactoryBot) |
| `Cell::TestCase` |  | Tests for legacy Trailblazer Cells |
| `ActionDispatch::IntegrationTest` | Rails integration | Controller & request tests (Devise helpers included) |
| `Folio::CapybaraTest` | IntegrationTest | Full-stack browser tests with Capybara |
| `Folio::ComponentTest` | `ViewComponent::TestCase` | Tests for ViewComponents |

Each base class automatically:
- Resets `Folio::Current` context (site/user)
- Includes `FactoryBot::Syntax::Methods`
- Provides helpers from `test/support/`

---

## Factories

Factories live in `test/factories.rb` and are loaded via FactoryBot. When you generate new models with Folio generators, remember to add corresponding factories.

```ruby
# Example factory
after(:build) { |file| file.file.attach(io: File.open('test/fixtures/files/sample.jpg'), filename: 'sample.jpg') }
```

---

## Running Tests

```sh
rails test           # run all tests
rails test test/models # run model tests only
rails test:system    # run Capybara system tests (if any)
```

Parallel testing is enabled by default (`parallelize` in `test_helper_base.rb`).

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
- [Next: Troubleshooting →](troubleshooting.md)

---

*This testing overview will be updated as the documentation evolves.* 