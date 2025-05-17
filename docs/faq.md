# FAQ – Frequently Asked Questions

Below are concise answers to common questions when working with the Folio Rails Engine. Every answer is verified against the current source code or official generators.

---

### 1. How do I add a new CMS block (Atom)?
Run the generator:
```sh
rails generate folio:atom MyBlock
```
This creates the model, component, tests, and i18n entries. Edit the generated files to add fields and rendering logic.

---

### 2. A newly scaffolded resource is missing from the admin sidebar. What now?
Add its console controller class to the initializer:
```ruby
config.folio_console_sidebar_link_class_names ||= []
config.folio_console_sidebar_link_class_names << "Folio::Console::ArticlesController"
```
Restart the server.

---

### 3. Where can I change the default locale of the admin console?
Set `config.folio_console_locale` in `config/initializers/folio.rb` (default `:cs`).

---

### 4. How do I share Devise sessions across sub-domains?
Enable cross-domain Devise cookies:
```ruby
config.folio_crossdomain_devise = true
```
Make sure Rails' session cookie domain is set appropriately.

---

### 5. Can I upload directly to Amazon S3?
Yes. Enable direct uploads:
```ruby
config.folio_direct_s3_upload_allow_public = true # or allow for users
```
See `config.folio_direct_s3_upload_*` options in `lib/folio/engine.rb` for more control.

---

### 6. My Capybara tests complain about missing `Folio::Current.site`. How do I fix this?
Inherit from the provided base classes (`Folio::CapybaraTest`, `Folio::BaseControllerTest`, etc.) which set up a site automatically. Alternatively call `Folio::Current.reset` and assign `Folio::Current.site` manually in test setup.

---

### 7. How do I add translation (Traco) to an existing model?
Run the Traco generator:
```sh
rails generate folio:traco title description
rails db:migrate
```
Add `traco :title, :description` to the model.

---

### 8. Can I disable OpenGraph fallback images?
Yes:
```ruby
config.folio_use_og_image = false
```

---

### 9. How do I send emails via a different provider?
Set delivery method in `config/environments/production.rb`, and configure credentials as usual. Folio mailers inherit from `Folio::ApplicationMailer`, so any ActionMailer setting applies.

---

### 10. Is Trailblazer Cell support still maintained?
Legacy Cells are supported but new development should use ViewComponent. Use the `folio:component` generator instead of `folio:cell`.

---

### 11. How do I customise user permissions?
Override `Folio::Ability` in `app/overrides/` and add rules using CanCan syntax. See the Abilities section in Admin chapter.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Extending & Customization](extending.md)

---

*Have a question not listed here? Create an issue on GitHub or check the Troubleshooting chapter.* 