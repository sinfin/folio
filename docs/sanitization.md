# HTML sanitization

This document provides guidelines and instructions for implementing HTML sanitization in your project.

## Overview

HTML sanitization ensures that all strings, texts, and JSON containing strings or texts are sanitized by default. This helps prevent potential security vulnerabilities and ensures consistent handling of HTML content across your application.

## Steps to Implement HTML Sanitization

1. **Update Your ApplicationRecord**:
   Make sure you have `include Folio::HtmlSanitization::Model` in your `ApplicationRecord`.

2. **Define Sanitization Configuration**:
   For models that may contain HTML attributes, define a `folio_html_sanitization_config` method to override the default configuration provided by the concern.

   Example configuration:
   ```rb
   def folio_html_sanitization_config
     {
       enabled: true,
       attributes: {
         attribute_1: :unsafe_html,
         attribute_2: :richtext,
         attribute_3: -> (value) { custom_sanitization_handler(value) },
       },
     }
   end
   ```

3. **Supported Attribute Values**:
   - `:unsafe_html`: Ignore the attribute and do not sanitize it.
   - `:richtext`: Keep safe HTML tags and attributes using `Rails::HTML5::SafeListSanitizer`.
   - proc: Pass a proc (i.e. `-> (value) { custom_sanitization_handler(value) }`) to handle custom sanitization logic.

4. **Default Behavior**:
   Attributes not defined in the `:attributes` hash are stripped of all HTML using `Loofah`.

5. **Disabling Sanitization**:
   You can disable sanitization for a specific model by setting `{ enabled: false }` in the configuration.

## Example: Custom Configuration for a Model

Here is an example override for `Folio::EmailTemplate`, where attributes starting with `body_html` are treated as rich text:

```rb
def folio_html_sanitization_config
  attributes_config = {}

  attribute_names.each do |attribute_name|
    if attribute_name.starts_with?("body_html")
      attributes_config[attribute_name.to_sym] = :richtext
    end
  end

  {
    enabled: true,
    attributes: attributes_config,
  }
end
```

By following these steps, you can ensure that your application handles HTML content securely and consistently.
