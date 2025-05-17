# Configuration

This chapter lists the most important configuration options for the Folio Rails Engine, shows where they are defined, and explains how to override them in your application.

---

## Where Configuration Lives

1. **Engine defaults** – Defined in `lib/folio/engine.rb`.
2. **Application overrides** – Set in `config/application.rb` *or* a dedicated initializer (e.g. `config/initializers/folio.rb`).
3. **Install generator** – Running `rails generate folio:install` creates a starter initializer with the most common settings.

---

## Key Configuration Options

| Option | Default | Purpose |
|--------|---------|---------|
| `config.folio_crossdomain_devise` | `false` | Enable shared Devise sessions across sub-domains |
| `config.folio_shared_files_between_sites` | `true` | Share uploaded files among all sites |
| `config.folio_pages_audited` | `false` | Keep an audit trail of page changes |
| `config.folio_pages_autosave` | `false` | Enable autosave in page forms |
| `config.folio_console_locale` | `:cs` | Default locale in admin console |
| `config.folio_console_clonable_enabled` | `true` | Allow record cloning in console |
| `config.folio_newsletter_subscription_service` | `:mailchimp` | Newsletter backend |
| `config.folio_use_og_image` | `true` | Provide OpenGraph fallback image |
| `config.folio_users_confirmable` | `false` | Require email confirmation |
| `config.folio_direct_s3_upload_allow_public` | `false` | Allow anonymous direct uploads to S3 |
| `config.folio_atom_files_url` | lambda | Builds file URLs inside atoms |
| `config.folio_cookie_consent_configuration` | hash | Settings for the cookie-consent banner |

*This is only a subset—see `lib/folio/engine.rb` for the full list.*

---

## Changing a Setting

Create or edit `config/initializers/folio.rb`:

```ruby
Rails.application.configure do
  # Set admin console to English
  config.folio_console_locale = :en

  # Use audited pages to track revisions
  config.folio_pages_audited = true
end
```

After changing configuration, restart your Rails server.

---

## Best Practices

- Keep all Folio settings in **one initializer** for easier maintenance.
- When generating new features (atoms, components, etc.) prefer generator defaults; they respect your config values.
- Document any project-specific overrides for future developers.

---

## SEO Helpers

### Canonical URL
Use the helper in your public controller:
```ruby
set_meta_tags canonical: canonical_url(@page)
```
`canonical_url` is provided by Folio and respects the current locale and site domain.

### Meta-variables in Controllers
Expose dynamic placeholders for email templates or OpenGraph meta:
```ruby
class ArticlesController < ApplicationController
  meta_variables :article_title, :author_name
end
```
These can be referenced in views via `meta_variable(:article_title)`.

---

## Cookie Consent Banner
Enable and configure the built-in cookie-consent component:
```ruby
config.folio_cookie_consent_configuration = {
  message: "We use cookies…",
  accept_text: "OK",
  policy_path: "/privacy"
}
```
It will automatically render at the bottom of every public page.

---

## Cross-domain Devise Sessions
Set both the Folio flag and Rails session domain:
```ruby
# config/initializers/folio.rb
config.folio_crossdomain_devise = true

# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store, key: "_myapp_session", domain: ".example.com"
```

---

## Traco Localisation Example
```sh
rails generate folio:traco title description
rails db:migrate
```
Model:
```ruby
class Article < ApplicationRecord
  traco :title, :description
end
```
YAML:
```yml
en:
  activerecord:
    attributes:
      article:
        title: "Title"
```

---

## Request Context – `Folio::Current`

Folio stores per-request data (site, user, ability) in the singleton `Folio::Current`.
Controllers inheriting from `Folio::ApplicationControllerBase` are wired automatically; if you use a custom base controller include `Folio::SetCurrentRequestDetails`.

In tests the helper base classes reset `Folio::Current` for you. In service objects you can reference `Folio::Current.site` or `Folio::Current.user`.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Emails & Templates](emails.md)
- [Next: Testing →](testing.md) 

---

*For more details, inspect `lib/folio/engine.rb` or run `rails runner 'puts Rails.application.config.inspect'`.* 