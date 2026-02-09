# Concerns

Folio extracts shared functionality into Ruby modules located under `app/models/concerns/folio/` and `app/controllers/concerns/folio/`. These modules can be mixed into your own classes to add behaviour or helper scopes.

## Model Concerns

### Publishing

#### `Folio::Publishable::Basic`
Boolean-based publishing without date. Adds `published` boolean attribute and scopes:
- `published` - returns records where `published = true`
- `unpublished` - returns records where `published != true` or `NULL`
- `published_or_preview_token(token)` - allows preview access via token

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::Publishable::Basic
end

Article.published  # Returns published articles
article.published? # Checks if article is published
article.publish!   # Sets published = true
article.unpublish!  # Sets published = false
```

#### `Folio::Publishable::WithDate`
Publishing with date support. Extends `Basic` with `published_at` datetime:
- Considers both `published` boolean and `published_at` date
- Only shows records where `published = true` AND `published_at <= now`
- Supports scheduled publishing

**Usage:**
```ruby
class NewsItem < ApplicationRecord
  include Folio::Publishable::WithDate
end

news_item.publish(published_at: 1.day.from_now)  # Schedule for future
news_item.publish!  # Publish now
```

#### `Folio::Publishable::Within`
Publishing within a date range. Uses `published_from` and `published_until`:
- Records are published only within the specified time window
- Useful for time-limited content (events, campaigns)

**Usage:**
```ruby
class Event < ApplicationRecord
  include Folio::Publishable::Within
end

event.publish(published_from: event.start_date, published_until: event.end_date)
```

### Content Management

#### `Folio::Tiptap::Model`
TipTap WYSIWYG editor integration. Provides rich text content management with JSON-based storage:
- Validates TipTap JSON structure
- Automatically manages file placements from editor content
- Supports revision history (autosave)
- Sanitizes HTML content
- `has_folio_tiptap_content` accepts `fields:` (default `[:tiptap_content]`) and optional `locales:` (see [Tiptap](tiptap.md#locale-support))

**Usage:**
```ruby
class Page < ApplicationRecord
  include Folio::Tiptap::Model
  
  has_folio_tiptap_content
end

page.tiptap_content = { "type": "doc", "content": [...] }  # TipTap JSON
page.latest_tiptap_revision(user: current_user)  # Get autosaved revision
```

#### `Folio::HasAtoms`
CMS block system (legacy). Adds association for content blocks:
- `Folio::HasAtoms::Commons` - Base functionality with single `atoms` association
- `Folio::HasAtoms::Localized` - Multi-locale atoms support

**Usage:**
```ruby
class Page < ApplicationRecord
  include Folio::HasAtoms::Commons  # or Folio::HasAtoms::Localized
end

page.atoms  # Returns associated atoms
page.atoms_in_molecules  # Groups atoms into molecules
```

### Attachments and Files

#### `Folio::HasAttachments`
Comprehensive file attachment management. Provides:
- `file_placements` - polymorphic association for file attachments
- Predefined associations: `cover`, `images`, `documents`, `tiptap_files`, `og_image`
- Automatic thumbnail generation triggers
- File usage validation and limits
- Counter cache support

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::HasAttachments
end

article.cover  # Returns cover image file
article.images  # Returns all image attachments
article.image_placements  # Returns image placements with metadata
article.cover_placement  # Returns cover placement record
article.og_image_with_fallback  # OG image or cover fallback
```

#### `Folio::Thumbnails`
Image thumbnail generation and management. Works with `Folio::HasAttachments`:
- Generates multiple thumbnail sizes
- Provides thumbnail URL helpers
- Supports pregeneration jobs

**Usage:**
```ruby
class Image < ApplicationRecord
  include Folio::Thumbnails
end

image.thumbnail_sizes  # Returns hash of available thumbnails
image.thumb_url(:small)  # Returns thumbnail URL for size
```

### Multi-Site and Localization

#### `Folio::BelongsToSite`
Multi-site support. Adds `site` association:
- Scopes queries by site
- Required for multi-site projects

**Usage:**
```ruby
class Page < ApplicationRecord
  include Folio::BelongsToSite
end

page.site  # Returns associated site
Page.by_site(site)  # Scope by site
```

#### `Folio::FriendlyId`
URL-friendly identifiers. Integrates with `friendly_id` gem:
- Generates slugs from `to_label` method
- Maintains slug history
- Supports scoped slugs (e.g., per site)

**Usage:**
```ruby
class Page < ApplicationRecord
  include Folio::FriendlyId
end

page.slug  # Returns URL-friendly slug
Page.friendly.find("my-page")  # Find by slug
```

#### `Folio::BelongsToSiteAndFriendlyId`
Combines `BelongsToSite` and `FriendlyId` with site-scoped slugs:
- Slugs are unique per site
- Automatically includes site slug in candidate generation

**Usage:**
```ruby
class Page < ApplicationRecord
  include Folio::BelongsToSiteAndFriendlyId
end

# Slug is unique per site
site1.pages.create!(title: "About")  # slug: "about"
site2.pages.create!(title: "About")  # slug: "about" (different site)
```

#### `Folio::Translatable`
Content localization. Manages translations as separate records:
- Links translations via `original_id`
- Supports multiple locales
- Handles translation duplication

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::Translatable
end

article.translate(:cs)  # Creates Czech translation
article.translations  # Returns all translations
article.translation(:cs)  # Returns specific translation
```

### Organization and Structure

#### `Folio::Positionable`
Ordering helpers for sortable lists. Adds position management:
- `ordered` scope for sorted queries
- Position manipulation methods

**Usage:**
```ruby
class MenuItem < ApplicationRecord
  include Folio::Positionable
end

MenuItem.ordered  # Returns items in position order
item.move_to_top!
item.move_to_bottom!
```

#### `Folio::HasAncestry`
Hierarchical structures. Uses `ancestry` gem for tree structures:
- Parent-child relationships
- Tree traversal methods
- Validates allowed child types

**Usage:**
```ruby
class Page < ApplicationRecord
  include Folio::HasAncestry
end

page.parent  # Returns parent page
page.children  # Returns child pages
page.descendants  # Returns all descendants
Page.arrange_as_array  # Returns flat array of tree
```

#### `Folio::Taggable`
Tagging support. Uses `acts-as-taggable-on`:
- Multiple tag lists
- Tag-based scoping

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::Taggable
end

article.tag_list = ["news", "technology"]
Article.tagged_with("news")
```

### Filtering and Search

#### `Folio::Filterable`
Dynamic filtering. Provides `filter_by_params` and `by_*` scopes:
- Automatically generates scopes from parameters
- Supports complex filtering logic

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::Filterable
end

Article.filter_by_params(q: "search", published: true)
```

### Security and Access

#### `Folio::HasSecretHash`
Secure token generation. Generates unique tokens for secure URLs:
- Preview tokens
- Share tokens
- One-time access links

**Usage:**
```ruby
class Document < ApplicationRecord
  include Folio::HasSecretHash
end

document.secret_hash  # Returns unique token
Document.find_by_secret_hash(token)  # Find by token
```

#### `Folio::Indestructible`
Protection against deletion. Prevents accidental deletion:
- Requires `force_destroy` flag to delete
- Useful for critical records

**Usage:**
```ruby
class Site < ApplicationRecord
  include Folio::Indestructible
end

site.destroy  # Raises error
site.force_destroy = true
site.destroy  # Allowed
```

### Special Patterns

#### `Folio::Singleton`
Singleton pattern. Ensures only one instance exists:
- Validates uniqueness
- Provides `instance` class method
- Automatically includes `Indestructible`

**Usage:**
```ruby
class Settings < ApplicationRecord
  include Folio::Singleton
end

Settings.instance  # Returns the single instance
Settings.create  # Raises error if instance exists
```

#### `Folio::Audited::Model`
Change auditing. Tracks model changes:
- Records create/update/destroy actions
- Stores changed relations
- Supports restoration

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::Audited::Model
  
  audited(relations: [:cover_placement])
end

article.audits  # Returns audit trail
article.reconstruct_folio_audited_data(audit: audit)  # Restore from audit
```

### Sitemap

#### `Folio::Sitemap::Base`
XML sitemap generation. Provides image sitemap helpers:
- Collects images from cover and image placements
- Formats for XML sitemap

**Usage:**
```ruby
class Article < ApplicationRecord
  include Folio::Sitemap::Base
end

article.image_sitemap(:large)  # Returns array of image sitemap entries
```

### Other Concerns

| Module | Purpose |
|--------|---------|
| `Folio::HasAddresses` | Primary and secondary address management |
| `Folio::HasRoles` | Role-based access control |
| `Folio::HasSiteRoles` | Site-specific roles |
| `Folio::HasFolioAttributes` | Ad-hoc attributes via `folio_attributes` association |
| `Folio::Sortable` | Alternative sorting implementation |
| `Folio::Featurable` | Feature flag support |
| `Folio::Imprintable` | Legal imprint requirements |
| `Folio::ToLabel` | Label generation for display |
| `Folio::NillifyBlanks` | Converts blank strings to nil |

See the source under [`app/models/concerns/folio`](../app/models/concerns/folio) for the complete list of all concerns.

## Controller Concerns

Controller modules live in `app/controllers/concerns/folio`. Important ones include:

- `Folio::ApplicationControllerBase` – sets `Folio::Current` context
- `Folio::PagesControllerBase` – helpers for page rendering
- `Folio::ApiControllerBase` – JSON API helpers
- `Folio::Console::DefaultActions` – common CRUD actions for admin controllers

Include these modules in custom controllers as needed.

---

[← Back to Architecture](architecture.md)
