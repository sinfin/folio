# Upgrading

## Unreleased

### Sidekiq 7 changes its Redis integration

Folio allows Sidekiq 6.5 and 7 for a staged worker rollout; its development
bundle resolves Sidekiq 7. Sidekiq 7 uses `redis-client` internally, requires
a Redis 6.2+ server, and no longer supports Redis namespaces. Folio's direct
`redis` dependency remains on 4.x for its batch-service API. Folio's video
monitor reads live jobs through `Sidekiq::WorkSet`, handling both Sidekiq 6
work hashes and Sidekiq 7 `Work#payload` objects.

**Action required when moving to Sidekiq 7:** Confirm the host app's Redis
server and Sidekiq Pro versions support Sidekiq 7. Replace namespace-based
Sidekiq configuration and review code that calls `Sidekiq.redis` or reads
live jobs through `Sidekiq::Workers`. Sidekiq 8 and Pro 8 require a separate
rollout; this Folio version does not permit Sidekiq 8.

### AASM 6 changes failed persistence behavior

AASM 6 defaults `whiny_persistence` to `true` (it was `false` in AASM 5).
Folio explicitly sets `whiny_persistence: false` on its state machines so a
bang event that cannot persist an invalid record returns `false` instead of
raising `ActiveRecord::RecordInvalid`.

**Action required:** Supply `whiny_persistence` explicitly in every host-app
`aasm` declaration. Use `aasm whiny_persistence: false do` to keep the previous
behavior, or `true` if the app intends to raise on failed persistence. Check
any error handling around bang events when choosing the value.

### ViewComponent templates require an explicit format

ViewComponent now warns when a component template does not declare its format.
Folio component templates use the `.html.slim` convention.

**Action required:** Rename ViewComponent templates in your app and packs from
`*_component.slim` to `*_component.html.slim`. Update custom generators that
create component templates. Ordinary Rails views and legacy Cell templates do
not need this rename.

### Console AASM email modal is a ViewComponent

`cell("folio/console/aasm/email_modal")` is replaced by
`render(Folio::Console::Aasm::EmailModalComponent.new)`.

The default console layout already renders the component. The cell Ruby, Slim,
JS, and Sass under `app/cells/folio/console/aasm/email_modal*` have been
removed.

**Action required:** If a host app still calls the cell (or copies the old
console layout with `cell("folio/console/aasm/email_modal")`), switch to the
component. I18n keys moved from `folio.console.aasm.email_modal` to
`folio.console.aasm.email_modal_component`.

### activejob-uniqueness is now activejob-unique

Folio now depends on `activejob-unique`, the Rails 8.1-compatible maintained
fork of `activejob-uniqueness`.

**Action required:** If your app explicitly depends on
`activejob-uniqueness`, replace it with `activejob-unique`. The
`ActiveJob::Uniqueness` API is unchanged.

## 7.2.* to 7.3.0

### has_folio_tiptap? Method Change

**BREAKING CHANGE**: `has_folio_tiptap?` has been changed from a class method to an instance method.

**Before (7.2.*):**
```ruby
Folio::Page.has_folio_tiptap?  # class method
```

**After (7.3.0):**
```ruby
page.has_folio_tiptap?  # instance method
```

**Action required:**

1. Update all code that calls `has_folio_tiptap?` as a class method to use it as an instance method
2. Update test stubs from `Folio::Page.stub(:has_folio_tiptap?, true)` to `page.stub(:has_folio_tiptap?, true)`
3. Search your codebase for `\.has_folio_tiptap\?` and `has_folio_tiptap\?` to find all usages

### tiptap_config Method Signature Change

**BREAKING CHANGE**: `tiptap_config` and `tiptap_autosave_enabled?` methods on models now accept an optional `attribute_name:` keyword argument to scope configuration per Tiptap attribute.

**Before (7.2.*):**
```ruby
class MyApp::Page < Folio::ApplicationRecord
  include Folio::Tiptap::Model

  def tiptap_config
    Folio::Tiptap::Config.new(...)
  end
end
```

**After (7.3.0):**
```ruby
class MyApp::Page < Folio::ApplicationRecord
  include Folio::Tiptap::Model

  def tiptap_config(attribute_name: nil)
    # attribute_name can be used to return different configs per field
    # When nil, return default/global config
    Folio::Tiptap::Config.new(...)
  end
end
```

**Action required:**

1. Update all model overrides that define `tiptap_config` to accept `attribute_name: nil` parameter:
   ```ruby
   # Old
   def tiptap_config
     ...
   end

   # New
   def tiptap_config(attribute_name: nil)
     ...
   end
   ```

2. If you have custom `tiptap_autosave_enabled?` overrides, update them similarly:
   ```ruby
   def tiptap_autosave_enabled?(attribute_name: nil)
     tiptap_config(attribute_name: attribute_name)&.autosave == true
   end
   ```

3. Search your codebase for `def tiptap_config` and `def tiptap_autosave_enabled?` to find all overrides

**Note**: The default implementation in `Folio::Tiptap::Model` already handles the new signature. This change only affects models that override these methods.

## 7.0.0 to 7.1.0

### TipTap Node Configuration Changes

**BREAKING CHANGE**: TipTap node configuration structure has been flattened. You must update all node class definitions.

#### Node Config Flattening

**Before (7.0.0):**

```ruby
# app/models/my_app/tiptap/node/contents/text.rb
tiptap_node structure: {
  content: :rich_text,
}, tiptap_config: {
  toolbar: {
    icon: "content_text",
    slot: "after_layouts",
  },
}
```

**After (7.1.0):**

```ruby
# app/models/my_app/tiptap/node/contents/text.rb
tiptap_node structure: {
  content: :rich_text,
}, tiptap_config: {
  icon: "content_text",              # Flattened from toolbar.icon
  toolbar_slot: "after_layouts",     # Flattened from toolbar.slot
}
```

#### Node Groups (New Feature)

Node groups allow organizing nodes into dropdown menus. This is an **optional** feature:

**1. Add `node_groups` to config (optional):**

```ruby
# app/models/my_app.rb
def self.default_tiptap_config
  ::Folio::Tiptap::Config.new(
    node_names: [...],
    node_groups: [  # Optional - new feature
      {
        key: "content",
        title: { cs: "Obsah", en: "Content" },
        icon: "content",
        toolbar_slot: "after_layouts",  # Optional - controls toolbar position
      },
    ],
  )
end
```

**2. Assign nodes to groups:**

```ruby
# app/models/my_app/tiptap/node/contents/text.rb
tiptap_node structure: {
  content: :rich_text,
}, tiptap_config: {
  icon: "content_text",
  toolbar_slot: "after_layouts",  # Optional - for individual button
  group: "content",                # Optional - for dropdown menu
}
```

**3. Independent `group` and `toolbar_slot`:**

- `group` and `toolbar_slot` are **independent** properties
- Nodes can have both and will appear in both places:
  - In the group dropdown menu (if they have `group`)
  - As individual toolbar buttons (if they have `toolbar_slot`)

**Action required:**

1. Search your codebase for `tiptap_config: { toolbar: {` and flatten to direct properties
2. Update all node class definitions:
   - `toolbar: { icon: "..." }` → `icon: "..."`
   - `toolbar: { slot: "..." }` → `toolbar_slot: "..."`
3. If using node groups, add `group: "..."` to node configs
4. Update TypeScript types if you have custom TipTap extensions:
   - Update property access from `node.config.toolbar.icon` to `node.config.icon`
   - Update property access from `node.config.toolbar.slot` to `node.config.toolbar_slot`

See [docs/tiptap.md](docs/tiptap.md) for complete documentation and examples.

## 6.5.* to 7.0.0

### Rails 8.0.1 Upgrade

- **Rails upgraded to 8.0.1** - Review Rails 8.0 upgrade guide and ensure all dependencies are compatible
- Update your Gemfile to use Rails 8.0.1
- Run `bundle update rails` and resolve any dependency conflicts

### Database Migrations

- **Folio::File hash_id -> slug**: Run the migration to rename `hash_id` column to `slug` in `folio_files` table
  ```ruby
  # Migration is included: 20251031141402_change_files_hash_id_to_slug.rb
  # Update any code referencing Folio::File#hash_id to use #slug instead
  ```
- Review and run all new migrations from Folio 6.x to 7.0.0

### Cells to ViewComponents Migration

The following Cells have been refactored to ViewComponents. Update your code:

- `Folio::Console::Form::HeaderCell` → `Folio::Console::Form::HeaderComponent`
- `Folio::PublishableHintCell` → `Folio::Publishable::HintComponent`

**Action required**: Search your codebase for references to these cells and update:
```ruby
# Old
cell("folio/console/form/header", ...)

# New
render(Folio::Console::Form::HeaderComponent.new(...))
```

### Console Controller Changes

- **Default `show` action redirects to `edit`**: If your controllers rely on the default `show` action, you must explicitly define it:
  ```ruby
  def show
    # Your custom show logic here
  end
  ```
  Controllers using `super` in `show` will now redirect to `edit` instead.

### API Changes

- **AjaxInputComponent API response format changed**: Update any custom API endpoints used by `Folio::Console::Ui::AjaxInputComponent`
  ```ruby
  # Old format
  { value: new_value }

  # New format
  { name => new_value }  # where name is the field name
  ```

### Configuration Changes

- **Devise modules**: Default `devise_modules` moved to Folio config. If you need custom modules, configure them in your Folio initializer:
  ```ruby
  Rails.application.config.folio_devise_modules = %i[database_authenticatable ...]
  ```

### File Upload System (Uppy)

- **Uppy File Uploader replaces legacy upload components**: If you have custom upload code using the old system, migrate to Uppy
- Review file upload forms and ensure they work with the new Uppy-based system
- Check that file replacement functionality still works as expected

### Autocomplete Inputs

- **Autocomplete redone without jQuery UI**: If you have custom autocomplete code relying on jQuery UI, update it to use the new implementation
- Custom autocomplete endpoints should continue to work, but verify behavior

### TipTap Editor

- **TipTap is now the primary rich text editor**: If migrating from Redactor or other editors, see [docs/tiptap.md](docs/tiptap.md) for migration guide
- Review all rich text fields and ensure they work with TipTap
- Update any custom TipTap extensions or configurations

### Embed System

- **Complete rewrite of embed functionality**: If using the old embed system, migrate to the new `EmbedInput` and `Folio::Embed::BoxComponent`
- See [docs/embed.md](docs/embed.md) for details on the new implementation
- Update models to include `Folio::Embed::Validation` concern if needed

### Testing

- Update test helpers if they reference deprecated Cells
- Review console controller tests for `show` action behavior changes
- Update API tests for `AjaxInputComponent` response format changes

## 6.4.1 to 6.5.0

- Replace `include Folio::HasSanitizedFields` with `include Folio::HtmlSanitization::Model` on your `ApplicationRecord`.
- Sanitizer **sanitizes all strings/texts and JSON containing strings/texts by default**.
  - Go through all of your models and pick the attributes that may contain HTML. Should such a model exist, define a `folio_html_sanitization_config` method (overriding the concern default) with the following syntax
  ```rb
  def folio_html_sanitization_config
    {
      enabled: true,
      attributes: {
        attribute_1: :unsafe_html,
        attribute_2: :rich_text,
        attribute_3: -> (value) { custom_sanitization_handler(value) },
      },
    }
  end
  ```
  - The following values are supported:
    - `:unsafe_html` - ignore the attribute, don't sanitize at all
    - `:rich_text` - keep safe HTML tags and attributes via `Rails::HTML5::SafeListSanitizer`
    - proc, i.e. `-> (value) { custom_sanitization_handler(value) }` - pass a proc which will be given value of attribute
  - Attributes not defined in the `:attributes` hash are stripped of all HTML using `Loofah`
  - You can disable the sanitization for your model by setting `{ enabled: false }`
  - Example override for `Folio::EmailTemplate` as the `body_html_*` can differ across projects:
  ```rb
  def folio_html_sanitization_config
    attributes_config = {}

    attribute_names.each do |attribute_name|
      if attribute_name.starts_with?("body_html")
        attributes_config[attribute_name.to_sym] = :rich_text
      end
    end

    {
      enabled: true,
      attributes: attributes_config,
    }
  end
  ```
