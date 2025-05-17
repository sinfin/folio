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

If newly scaffolded resources do not appear in the admin sidebar, check:
- `config/initializers/folio.rb` – option `config.folio_console_sidebar_link_class_names` should include your model's console controller class.
- The generated controller inherits from `Folio::Console::BaseController` and the policy permits `index`.

---

## Database-Related Errors in Tests

Use the provided test base classes—each resets `Folio::Current` and sets up a `Site` record. If you skip them you may see:
```
Folio::Current::MissingSite: No current site is set
```
Fix by inheriting from `Folio::ComponentTest`, `Folio::BaseControllerTest`, etc.

---

## Need More Help?

1. Re-run the relevant Folio generator to compare with generated code.  
2. Enable debug logging: `rails s -e development` and set `config.log_level = :debug` in `config/environments/development.rb`.  
3. Search existing GitHub issues: <https://github.com/sinfin/folio/issues>.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Testing](testing.md)
- [Next: Upgrade & Migration →](upgrade.md)

---

*This list will grow as more issues are collected from real-world projects.* 