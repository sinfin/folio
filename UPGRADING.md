# Upgrading

## 6.4.0 to Unreleased - HTML sanitization

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
