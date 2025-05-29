# Troubleshooting

This chapter collects common issues encountered when working with the Folio Rails Engine, together with proven solutions. All items are verified against the original Folio wiki or current source code.

---

## Missing Redactor Assets

**Symptom**
```
SassC::SyntaxError: Error: File to import not found or unreadable: redactor.
```

**Cause**
Folio depends on licensed **Redactor 3** assets. The installer expects them under `vendor/assets/redactor/`.

**Solution**
1. Purchase / download Redactor 3 from <https://imperavi.com/redactor/>.
2. Copy the contents to `vendor/assets/redactor/` so the paths look like:
   - `vendor/assets/redactor/redactor.js`
   - `vendor/assets/redactor/redactor.css`
3. For local development you can create **empty placeholder files** with those names to unblock the asset pipeline, but the editor will not work until real files are provided.

---

## Engine Namespace Not Loaded in Development

**Symptom**
Generated table names are missing the expected prefix and you see model-not-found errors.

**Cause**
Folio expects your application namespace module to be loaded so `self.table_name_prefix` is applied. The install generator adds `<app_namespace>.rb` in `app/models/` and an initializer to require it. If this initializer is missing, Rails autoloader may skip the namespace file on boot.

**Solution**
1. Ensure the file `app/models/<your_app>.rb` exists and defines the module, e.g.:
   ```ruby
   module MyApp
     def self.table_name_prefix
       "my_app_"
     end
   end
   ```
2. Ensure `config/initializers/namespace.rb` requires it:
   ```ruby
   require Rails.root.join("app/models/my_app")
   ```
3. Restart the server.

---

## Debugging Console Sidebar Links

If newly scaffolded resources do not appear in the admin sidebar:
- add class to one of `console_sidebar_prepended_links`, `console_sidebar_before_menu_links`, `console_sidebar_before_site_links` in your `Folio::Site` subclass
- add class to `config/initializers/folio.rb` – option `config.folio_console_sidebar_link_class_names`

---

## Database-Related Errors in Tests

Use the provided test base classes—each resets `Folio::Current` and sets up a `Site` record. If you skip them you may see:
```
Folio::Current::MissingSite: No current site is set
```
Fix by inheriting from `Folio::ComponentTest`, `Folio::BaseControllerTest`, etc., or by seeding it with `create_and_host_site` or `get_any_site`.

---

## HTML Sanitization Issues

### Symptom: HTML Content is Being Stripped

If your HTML content is being stripped, it is likely caused by the default sanitization behavior. By default, attributes not explicitly defined in the `:attributes` hash of the `folio_html_sanitization_config` method are sanitized using `Loofah`, which removes all HTML tags.

### Solution: Disable Sanitization for a Specific Model

To disable sanitization for a specific model, override the `folio_html_sanitization_config` method in the model and set `{ enabled: false }` in the configuration. For example:

```ruby
def folio_html_sanitization_config
  { enabled: false }
end
```

This will bypass all sanitization for the model.

### Solution: Allow Specific Attributes to Contain HTML

You can allow specific HTML tags and attributes by using the `:rich_text` configuration. This uses `Rails::HTML5::SafeListSanitizer`, which keeps safe HTML tags and attributes.

- Use `:unsafe_html` to completely disable sanitization for a specific attribute.
- For more granular control, define a custom proc to handle sanitization logic for specific attributes.

## Need More Help?

1. Re-run the relevant Folio generator to compare with generated code.
2. Enable debug logging: `rails s -e development` and set `config.log_level = :debug` in `config/environments/development.rb`.
3. Search existing GitHub issues: <https://github.com/sinfin/folio/issues>.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to HTML Sanitization](sanitization.md)
- [Next: Upgrade & Migration →](upgrade.md)

---

*This list will grow as more issues are collected from real-world projects.*
