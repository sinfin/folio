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

- add class to one of `console_sidebar_prepended_links`, `console_sidebar_before_menu_links`, `console_sidebar_before_site_links` in your `Folio::Site` subclass
- add class to `config/initializers/folio.rb` – option `config.folio_console_sidebar_link_class_names`

---

### 3. Where can I change the default locale of the admin console?
Set `config.folio_console_locale` in `config/initializers/folio.rb` (default `:cs`).

---

### 4. How do I share Devise sessions across sub-domains?
Enable Folio cross-domain functionality:
```ruby
config.folio_crossdomain_devise = true
```

---

### 5. Can I upload directly to Amazon S3?

Yes. Folio components only use direct S3 uploads.

---

### 6. My Capybara tests complain about missing `Folio::Current.site`. How do I fix this?
Inherit from the provided base classes (`Folio::CapybaraTest`, `Folio::BaseControllerTest`, etc.) which set up a site automatically. Alternatively call `Folio::Current.reset` and assign `Folio::Current.site` manually in test setup.

---

### 7. Can I disable OpenGraph fallback images?
Yes:
```ruby
config.folio_use_og_image = false
```

---

### 8. How do I send emails via a different provider?
Set delivery method in `config/environments/production.rb`, and configure credentials as usual. Folio mailers inherit from `Folio::ApplicationMailer`, so any ActionMailer setting applies.

---

### 9. Is Trailblazer Cell support still maintained?
Legacy Cells are supported but new development should use ViewComponent. Use the `folio:component` generator instead of `folio:cell`.

---

### 10. How do I customise user permissions?
Override `Folio::Ability` in `app/overrides/` and add rules using CanCan syntax. See the Abilities section in Admin chapter.

---

### 11. Why is my HTML being stripped?

If your HTML content is being stripped, it is likely caused by the default sanitization behavior. By default, attributes not explicitly defined in the `:attributes` hash of the `folio_html_sanitization_config` method are sanitized using `Loofah`, which removes all HTML tags. To preserve specific HTML content, ensure that the attribute is included in the `:attributes` hash with the appropriate sanitization configuration, such as `:rich_text` or a custom proc.

#### 11a. How do I disable sanitization for a specific model?

To disable sanitization for a specific model, override the `folio_html_sanitization_config` method in the model and set `{ enabled: false }` in the configuration. For example:

```rb
def folio_html_sanitization_config
  { enabled: false }
end
```

This will bypass all sanitization for the model.

#### 11b. Can I allow only some attributes to contain HTML?

Yes, you can allow specific HTML tags and attributes by using the `:rich_text` configuration. This uses `Rails::HTML5::SafeListSanitizer`, which keeps safe HTML tags and attributes.

You can use `:unsafe_html` to completely disable sanitization for a specific attribute.

If you need more granular control, you can define a custom proc to handle sanitization logic for specific attributes.

See [Sanitization](sanitization.md) for more information.

#### 11c. What is the default behavior for attributes not listed in the configuration?

Attributes not explicitly listed in the `:attributes` hash of the `folio_html_sanitization_config` method are sanitized using `Loofah`, which removes all HTML tags. This ensures that any unconfigured attributes are stripped of potentially unsafe HTML content by default.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Extending & Customization](extending.md)

---

*Have a question not listed here? Create an issue on GitHub or check the Troubleshooting chapter.*
