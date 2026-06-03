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
| `config.folio_files_video_default_processing_provider` | `:direct_file` | Default provider key for new video processing |
| `config.folio_files_video_playback_provider_classes` | direct-file mapping | Provider key to class-name registry; optional provider packs extend it |

*This is only a subset—see `lib/folio/engine.rb` and enabled pack entry modules
for the full list.*

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

### Cloudflare Stream

For host applications using `Folio::CloudflareStream::FileProcessing`, enable the
pack before engine initializers run:

```ruby
Folio.enabled_packs += [:cloudflare_stream]
```

Then configure:

```sh
CLOUDFLARE_STREAM_ACCOUNT_ID=todo-account-id
CLOUDFLARE_STREAM_CUSTOMER_SUBDOMAIN=customer-code.cloudflarestream.com
CLOUDFLARE_STREAM_API_TOKEN=find-me-in-vault
CLOUDFLARE_STREAM_ALLOWED_ORIGINS=www.example.com,example.com
CLOUDFLARE_STREAM_REQUIRE_SIGNED_URLS=false
CLOUDFLARE_STREAM_SIGNED_URL_TOKEN_EXPIRES_IN=3600
CLOUDFLARE_STREAM_MONITOR_STALE_AFTER=300
```

The provider requires the account id and API token. The token should be scoped to
the target account with Stream Write permission. The customer subdomain is not
required by Folio runtime; it is useful operational context for checking returned
playback URLs.

`CLOUDFLARE_STREAM_ALLOWED_ORIGINS` is optional. When present, Folio passes it
to Stream as `allowedOrigins` for new videos. Keep
`CLOUDFLARE_STREAM_REQUIRE_SIGNED_URLS=false` for public SEO videos; host
applications can override the per-video hook for protected content that should
require signed playback. Signed playback URLs are minted through the Stream
token API and use `CLOUDFLARE_STREAM_SIGNED_URL_TOKEN_EXPIRES_IN` as their
token lifetime.

If the host application schedules `Folio::CloudflareStream::MonitorProcessingJob`,
`CLOUDFLARE_STREAM_MONITOR_STALE_AFTER` controls how old the last progress check
must be before Folio treats the polling chain as lost and enqueues a new
`CheckProgressJob`.

The Cloudflare Stream pack registers these config defaults when enabled:

| Setting | Default | Purpose |
|---------|---------|---------|
| `config.folio_cloudflare_stream_account_id` | `ENV["CLOUDFLARE_STREAM_ACCOUNT_ID"]` | Cloudflare Stream account id for video processing |
| `config.folio_cloudflare_stream_api_token` | `ENV["CLOUDFLARE_STREAM_API_TOKEN"]` | Cloudflare Stream API token with Stream Write permission |
| `config.folio_cloudflare_stream_allowed_origins` | `ENV["CLOUDFLARE_STREAM_ALLOWED_ORIGINS"]` | Comma-separated Stream embed origins for new videos |
| `config.folio_cloudflare_stream_require_signed_urls` | `false` | Whether new Stream videos require signed playback URLs |
| `config.folio_cloudflare_stream_source_url_expires_in` | `2.hours` | Expiration window for short-lived source URLs passed to Stream |
| `config.folio_cloudflare_stream_signed_url_token_expires_in` | `ENV["CLOUDFLARE_STREAM_SIGNED_URL_TOKEN_EXPIRES_IN"]` or `1.hour` | Expiration window for Stream signed playback tokens |
| `config.folio_cloudflare_stream_poll_interval` | `30.seconds` | Delay between Stream processing status checks |
| `config.folio_cloudflare_stream_max_poll_attempts` | `240` | Maximum Stream polling attempts before marking processing failed |
| `config.folio_cloudflare_stream_monitor_stale_after` | `ENV["CLOUDFLARE_STREAM_MONITOR_STALE_AFTER"]` or `5.minutes` | Age after which the monitor cron re-schedules a lost Stream progress check |

---

## Best Practices

- Keep all Folio settings in **one initializer** for easier maintenance.
- When generating new features (atoms, components, etc.) prefer generator defaults; they respect your config values.
- Document any project-specific overrides for future developers.

---

## SEO Helpers

## Cookie Consent Banner
Enable and configure the built-in cookie-consent component:
```ruby
config.folio_cookie_consent_configuration = {
  enabled: true,
  cookies: {
    necessary: [
      ...
    ]
    ...
  }
}
```
It will automatically render at the bottom of every public page.

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
