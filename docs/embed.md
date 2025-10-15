# Embed

This chapter describes the Embed functionality in Folio. The module provides validation, URL detection, and data normalization for embedded content from supported social media platforms.

## TLDR

**Quick Usage**: Use `input as: :embed` in your forms to add embed functionality to your models. The input accepts a hash with either HTML content or supported platform URLs (YouTube, Instagram, Pinterest, Twitter/X).

```rb
# In your form
<%= f.input :folio_embed_data, as: :embed %>

# In your view
<%= render(Folio::Embed::BoxComponent.new(folio_embed_data: @model.folio_embed_data)) %>

# In your model (for validation)
class MyModel < ApplicationRecord
  include Folio::Embed::Validation
end
```

## Overview

The `Folio::Embed` module handles validation and processing of embedded content from various social media platforms. It supports YouTube, Instagram, Pinterest, and Twitter/X embeds with proper URL pattern validation and data structure normalization.

## Supported Platforms

The module supports the following platforms with their respective URL patterns:

- **Instagram**: `https://www.instagram.com/p/{id}` or `https://www.instagram.com/reel/{id}`
- **Pinterest**: `https://pinterest.com/pin/{id}` (including subdomain variants)
- **Twitter/X**: `https://twitter.com/{id}` or `https://x.com/{id}`
- **YouTube**: `https://www.youtube.com/watch?v={id}` or `https://youtu.be/{id}`

## Validation

### Using the Validation Concern

For models that need embed validation, include the `Folio::Embed::Validation` concern:

```rb
class MyModel < ApplicationRecord
  include Folio::Embed::Validation
  
  # The concern automatically validates the :folio_embed_data attribute
  # Your model must have a folio_embed_data attribute/method
end
```

### Manual Validation

You can also validate embed data manually using the module methods:

```rb
# Validate a record's embed data
Folio::Embed.validate_record(record: my_record, attribute_name: :folio_embed_data)

# Check if embed data is invalid and get the reason
reason = Folio::Embed.invalid_reason_for(embed_data)
```

### Validation Rules

Embed data is considered valid when:

1. **Not blank**: The embed data must be present
2. **Proper structure**: Must be a Hash with `"active" => true`
3. **Content requirement**: Must have either:
   - Custom HTML content in the `"html"` field, OR
   - Valid `"type"` and `"url"` fields matching supported platform patterns

### Error Types

The validation can return the following error keys:

- `:blank` - When embed data is missing or inactive
- `:invalid` - When data structure is wrong or URL doesn't match platform patterns

## URL Detection and Type Resolution

### Detecting Platform Type

Use `url_type` to detect which platform a URL belongs to:

```rb
Folio::Embed.url_type("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
# => "youtube"

Folio::Embed.url_type("https://www.instagram.com/p/ABC123/")
# => "instagram"

Folio::Embed.url_type("https://invalid-url.com")
# => nil
```

## Data Normalization

### Normalizing Input Values

The `normalize_value` method handles various input formats and converts them to a standardized structure:

```rb
# From hash input
hash_data = {
  "active" => true,
  "type" => "youtube",
  "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
Folio::Embed.normalize_value(hash_data)
# => { "active" => true, "type" => "youtube", "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }

# From JSON string
json_string = '{"active":true,"html":"<iframe>...</iframe>"}'
Folio::Embed.normalize_value(json_string)
# => { "active" => true, "html" => "<iframe>...</iframe>" }

# Inactive embeds return nil
inactive_data = { "active" => false, "url" => "https://youtube.com/..." }
Folio::Embed.normalize_value(inactive_data)
# => nil
```

### Data Structure

The normalized embed data structure includes the following fields:

- **active** (Boolean): Whether the embed is active/enabled
- **html** (String, optional): Custom HTML content for the embed
- **type** (String, optional): Platform type ("youtube", "instagram", "pinterest", "twitter")
- **url** (String, optional): The original platform URL

## Strong Parameters Integration

### Parameter Permissions

Use `hash_strong_params_keys` to get the allowed parameter keys for strong parameters:

```rb
def embed_params
  params.require(:embed).permit(Folio::Embed.hash_strong_params_keys)
end
```

The method returns: `[:active, :html, :type, :url]`

## Implementation Details

### Platform URL Patterns

The module uses regular expressions to validate platform URLs:

```rb
SUPPORTED_TYPES = {
  "instagram" => %r{https://(?:www\.)?instagram\.com/(?:p|reel)/([a-zA-Z0-9\-_]+)/?},
  "pinterest" => %r{https://(?:\w+\.)?pinterest\.com/pin/([a-zA-Z0-9\-_]+)/?},
  "twitter" => %r{https://(?:www\.)?(?:twitter\.com|x\.com)/([a-zA-Z0-9\-_]+)/?},
  "youtube" => %r{https://(?:www\.youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9\-_]+)/?},
}
```

### Combined Regex Pattern

For efficient URL matching, the module creates a combined regex with named capture groups:

```rb
TYPE_REGEX = Regexp.new(
  "^(" +
  SUPPORTED_TYPES.map do |type, regex|
    "(?<#{type}>#{regex.source})"
  end.join("|") +
  ")$",
  Regexp::EXTENDED
)
```

## Form Integration

### EmbedInput

Folio provides a specialized form input for handling embed data with real-time validation and preview functionality.

#### Basic Usage

```rb
# In your form
<%= f.input :folio_embed_data, as: :embed %>

# With compact mode (smaller interface)
<%= f.input :folio_embed_data, as: :embed, compact: true %>
```

#### How EmbedInput Works

The `EmbedInput` class (`app/inputs/embed_input.rb`) extends `SimpleForm::Inputs::StringInput` and provides:

1. **Hidden Field**: Creates a hidden input field that stores the JSON representation of embed data
2. **Stimulus Integration**: Uses `f-input-embed` Stimulus controller for interactive behavior
3. **Validation**: Validates input using `Folio::Embed.invalid_reason_for` before saving
4. **Normalization**: Automatically normalizes input data using `Folio::Embed.normalize_value`
5. **Component Rendering**: Renders the `Folio::Input::Embed::InnerComponent` for the user interface

The input accepts various formats (Hash, JSON string) and converts them to a standardized structure.

### Input Components

#### Folio::Input::Embed::InnerComponent

This component (`app/components/folio/input/embed/inner_component.rb`) provides the interactive interface for entering embed data:

**Features:**
- Real-time URL validation and type detection
- Preview of embedded content
- Support for both URL and raw HTML input
- Visual feedback for validation states (`blank`, `valid-url`, `invalid-url`, `valid-html`)
- Help text showing supported URL patterns

**States:**
- `blank` - No data entered
- `valid-url` - Valid platform URL detected
- `invalid-url` - URL doesn't match supported patterns
- `valid-html` - Custom HTML content provided

The component automatically detects platform types and validates URLs against supported patterns.

## Display Components

### Folio::Embed::BoxComponent

For displaying embedded content on the frontend, use the `Folio::Embed::BoxComponent`:

```rb
# Basic usage
<%= render(Folio::Embed::BoxComponent.new(folio_embed_data: @post.folio_embed_data)) %>

# With custom options
<%= render(Folio::Embed::BoxComponent.new(
  folio_embed_data: @post.folio_embed_data,
  centered: false,
  data: { "custom" => "attributes" }
)) %>
```

**Component Features:**
- Lazy loading with intersection observer
- Message-based communication with embedded iframes
- Stimulus controller `f-embed-box` for interaction handling
- Configurable centering and custom data attributes

### Embed Middleware

The `Rack::Folio::EmbedMiddleware` (`app/lib/rack/folio/embed_middleware.rb`) serves the embed widget at `/folio/embed`. This middleware:

1. Intercepts requests to `/folio/embed`
2. Serves a pre-built HTML file from `data/embed/dist/folio-embed-dist.html`
3. Supports development mode with `ENV["FOLIO_EMBED_DEV"]` for dynamic reloading
4. Provides the foundation for iframe-based embed rendering

## Middleware HTML File Build System

### Source Files

The HTML file served by the middleware is built from source files in `data/embed/source/`:

- **`embed.html`** - HTML template with placeholders for CSS and JavaScript
- **`embed.css`** - Styling for embed rendering, including loading states and platform-specific layouts
- **`embed.js`** - JavaScript logic for handling different embed types and platform integration

### Build Process

The build process combines the source files into a single HTML file using `data/embed/bin/create-static-embed-html`:

```bash
# Build the middleware HTML file
./data/embed/bin/create-static-embed-html
```

**Build script workflow:**

1. **Read template**: Loads `embed.html` template with CSS and JavaScript placeholders
2. **Inject CSS**: Replaces `/*! folio-embed-css */` placeholder with contents of `embed.css`
3. **Inject JavaScript**: Replaces `// folio-embed-javascript //` placeholder with contents of `embed.js`
4. **Generate output**: Creates `data/embed/dist/folio-embed-dist.html` with all assets inlined

## Usage Examples

### Basic Model Integration

```rb
class BlogPost < ApplicationRecord
  include Folio::Embed::Validation
  
  # Embed data will be automatically validated
  # Requires a folio_embed_data attribute/method
end
```

### Custom Attribute Name

For validating custom attribute names, use the module method directly:

```rb
class Article < ApplicationRecord
  validate :validate_social_embed
  
  private
  
  def validate_social_embed
    Folio::Embed.validate_record(record: self, attribute_name: :social_embed)
  end
end
```

### Complete Form Example

```rb
# In your form view
<%= simple_form_for @post do |f| %>
  <%= f.input :title %>
  <%= f.input :content %>
  <%= f.input :folio_embed_data, as: :embed, hint: "Enter a URL or custom HTML" %>
  <%= f.submit %>
<% end %>
```

### Display Example

```rb
# In your show view
<% if @post.folio_embed_data.present? %>
  <div class="post-embed">
    <%= render(Folio::Embed::BoxComponent.new(folio_embed_data: @post.folio_embed_data)) %>
  </div>
<% end %>
```
