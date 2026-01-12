# Upgrading

## 7.1.* to 7.2.0

### has_folio_tiptap? Method Change

**BREAKING CHANGE**: `has_folio_tiptap?` has been changed from a class method to an instance method.

**Before (7.1.*):**
```ruby
Folio::Page.has_folio_tiptap?  # class method
```

**After (7.2.0):**
```ruby
page.has_folio_tiptap?  # instance method
```

**Action required:**

1. Update all code that calls `has_folio_tiptap?` as a class method to use it as an instance method
2. Update test stubs from `Folio::Page.stub(:has_folio_tiptap?, true)` to `page.stub(:has_folio_tiptap?, true)`
3. Search your codebase for `\.has_folio_tiptap\?` and `has_folio_tiptap\?` to find all usages

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
