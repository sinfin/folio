# Image Metadata Extraction

## Overview

This feature enables automatic extraction and mapping of EXIF/IPTC/XMP metadata from uploaded images to database fields and JSON storage, following international IPTC standards for content management systems.

The system provides a clean, extensible architecture with full I18n support and intelligent fallbacks for all file types.

## Architecture

The metadata system follows clean architecture principles with clear separation of concerns:

```ruby
# Image-specific metadata extraction (service-based)
Folio::File (base model - no metadata extraction)
└── Folio::File::Image (Image files only)
    ├── Simplified metadata accessors (read from file_metadata JSONB)
    └── Delegates to Folio::Metadata::ExtractionService

# Service layer for business logic
Folio::Metadata::ExtractionService (core extraction logic)
├── extract!(force: false, user_id: nil) - main extraction method
├── extract_during_processing! - synchronous processing extraction
├── should_extract?(image) - validation logic
└── Delegates to IptcFieldMapper for field mapping

Folio::Metadata::IptcFieldMapper (mapping & formatting)
├── FIELD_MAPPINGS: field priorities with fallbacks
├── COMPLEX_FIELD_PROCESSORS: formatting logic
└── I18n support: locale-aware processing
```

### JSON-Based Metadata Storage

The system uses a hybrid approach combining database columns for essential fields with JSON storage for comprehensive metadata preservation:

```ruby
# Essential database columns (user-editable + indexable)
headline: string              # Editorial title/headline
author: string               # Creator/photographer (comma-joined)
description: text            # Caption/description
alt: string                  # Accessibility text
attribution_source: string   # Credit line/agency
attribution_copyright: string # Copyright notice
capture_date: datetime       # Photo creation timestamp
gps_latitude: decimal(10,6)  # GPS coordinates
gps_longitude: decimal(10,6) # GPS coordinates

# JSON metadata storage (complete preservation)
file_metadata: json          # Raw EXIF/IPTC/XMP data + processed values
file_metadata_extracted_at: datetime # Extraction timestamp
```

## Setup and Configuration

### 1. Database Migration

Run the Folio migration to add essential metadata fields:

```bash
rails folio:install:migrations
rails db:migrate
```

This adds 5 essential columns optimized for user editing and database queries, avoiding schema explosion.

### 2. Basic Configuration

Create `config/initializers/folio_image_metadata.rb`:

```ruby
# frozen_string_literal: true

# Folio Image Metadata Configuration
Rails.application.configure do
  # Enable automatic metadata extraction
  config.folio_image_metadata_extraction_enabled = true
  
  # ExifTool options for metadata extraction
  # -G1: Add group prefixes to field names
  # -struct: Extract structured XMP data  
  # -n: Print numerical values for GPS/timestamps
  # -charset iptc=utf8: Force UTF-8 interpretation (fixes Czech/Slovak mojibake)
  config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"]
  
  # Auto-populate user-editable fields from extracted metadata (only blank fields)
  config.folio_image_metadata_populate_user_fields = {
    headline: :headline,                    # Editorial title -> headline field
    author: :creator,                       # Creator -> author field (comma-joined)
    description: :description,              # Description -> description field
    attribution_copyright: :copyright_notice, # Copyright -> attribution_copyright field
    capture_date: :capture_date             # Original date -> capture_date field
  }
  
  # Merge extracted keywords into tag_list system
  config.folio_image_metadata_merge_keywords_to_tags = true
  
  # Language priority for multi-language metadata (e.g., XMP Lang Alt fields)
  config.folio_image_metadata_locale_priority = [:en, "x-default"]
end
```

### 3. I18n Setup

Add metadata translations to your locale files:

**config/locales/console/file.en.yml:**
```yaml
en:
  folio:
    console:
      file:
        # ... existing file translations
        
        # Metadata field labels (used by React via _translations.slim)
        metadata:
          headline: "Headline"
          description: "Description"
          creator: "Creator"
          camera_make: "Camera Make"
          flash: "Flash"
          # ... more fields
          
  # Backend processor translations (used by IptcFieldMapper)
  folio:
    metadata:
      flash:
        not_used: "Not used"
        used: "Used"
        used_with_value: "Used (%{value})"
      # ... more formatted values
```

**config/locales/console/file.cs.yml:**
```yaml
cs:
  folio:
    console:
      file:
        # ... existing file translations
        
        # Metadata field labels (used by React via _translations.slim)
        metadata:
          headline: "Titulek"
          description: "Popis"
          creator: "Autor" 
          camera_make: "Výrobce fotoaparátu"
          flash: "Blesk"
          # ... more fields
          
  # Backend processor translations (used by IptcFieldMapper)
  folio:
    metadata:
      flash:
        not_used: "Nepoužit"
        used: "Použit"
        used_with_value: "Použit (%{value})"
      # ... more formatted values
```

## Metadata Extraction Process

### 1. Upload and Extraction

When an image is uploaded:

```ruby
# app/models/folio/file/image.rb
# Triggered after file creation
after_commit :extract_metadata_async, on: :create, if: :should_extract_metadata?

# Delegates to service
def extract_metadata_async
  Folio::Metadata::ExtractionService.extract_async(self)
end

def should_extract_metadata?
  Folio::Metadata::ExtractionService.should_extract?(self)
end

# app/services/folio/metadata/extraction_service.rb
# Background job extracts metadata with UTF-8 charset
def extract!(force: false, user_id: nil)
  metadata = extract_raw_metadata_with_exiftool(@image)
  map_and_store_metadata(@image, metadata)
  # Returns: { "XMP-dc:Creator" => ["John Doe"], "IPTC:Headline" => "News", ... }
end
```

### 2. Field Mapping and Processing

The `ExtractionService` delegates to `IptcFieldMapper` for field mapping with fallbacks and I18n support:

```ruby
# app/services/folio/metadata/extraction_service.rb
def map_and_store_metadata(image, raw_metadata)
  # Store raw metadata in JSON column
  image.file_metadata = raw_metadata
  image.file_metadata_extracted_at = Time.current

  # Map using existing field mapper
  mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
  # => { headline: "News Photo", creator: ["John Doe"], flash: "Nepoužit", ... }

  # Store processed metadata in JSON for getters
  store_processed_metadata_for_getters(image, mapped_data)

  # Update database fields from mapped data (only blank fields)
  update_database_fields(image, mapped_data)

  # Merge keywords into tag_list if configured
  merge_keywords_to_tags(image, mapped_data)
end
```

### 3. Dynamic Metadata Access

Image files have simplified metadata accessors that read directly from the `file_metadata` JSONB field:

```ruby
# app/models/folio/file/image.rb - Simplified accessors
def title
  headline.presence || file_metadata&.dig("headline")
end

def caption
  description.presence || file_metadata&.dig("caption")
end

def keywords_list
  file_metadata&.dig("keywords") || []
end

def creator_list
  file_metadata&.dig("creator") || []
end

def copyright_info
  file_metadata&.dig("copyright_notice")
end

# Usage examples
image.title                      # => "Actual headline" (database or JSON)
image.creator_list               # => ["John Doe", "Jane Smith"]
image.keywords_list              # => ["news", "politics"]
image.copyright_info             # => "© 2024 ČTK"

# Non-image files don't have metadata extraction
document.respond_to?(:creator_list)  # => false
video.respond_to?(:keywords_list)    # => false
```

## User Interface

### File Modal Layout

**Editable Fields** (form inputs):
- Headline (Titulek)
- Description (Popis) 
- Alt text
- Author (Autor)
- Attribution fields (Zdroj, Copyright, Licence)
- Default crop settings

**Read-Only Metadata Display** (organized tables):
- **Descriptive**: Headline, Creator(s), Keywords, Caption Writer, Source
- **Technical**: Camera info, Capture date, GPS, Dimensions, Flash settings
- **Rights**: Copyright, Usage terms, Rights URL
- **Location**: Created/Shown locations, City, Country, GPS coordinates

### Live Updates

React components receive real-time updates via MessageBus:

```javascript
// MessageBus listener for metadata extraction completion
if (msg.type === 'Folio::File::MetadataExtracted' && msg.file) {
  const updatedFile = { ...this.props.fileModal.file, attributes: { ...msg.file.attributes }}
  this.props.dispatch(updatedFileModalFile(updatedFile))
}
```

### I18n Frontend Integration

Labels are automatically localized via Rails translations:

```javascript
// React component automatically uses Rails I18n.locale
const descriptiveFields = [
  { 
    key: 'headline_from_metadata', 
    label: window.FolioConsole.translations['file/metadata/headline'] || 'Headline' 
  },
  // ... more fields with automatic fallbacks
]
```

## Advanced Customization

### Custom Field Mappings

Override default field sources or add completely new fields:

```ruby
# config/initializers/folio_image_metadata.rb
Rails.application.config.folio_image_metadata_field_mappings = {
  # Override existing field to prefer different sources
  headline: [
    "MyApp:CustomHeadline",      # Your app-specific field first
    "XMP-photoshop:Headline",    # Then standard fields
    "IPTC:Headline"
  ],
  
  # Add completely new custom field
  internal_photo_id: [
    "MyApp:PhotoID",
    "XMP-myapp:PhotoID"
  ]
}
```

### Custom Field Processors

Add custom formatting and business logic with I18n support:

```ruby
Rails.application.config.folio_image_metadata_field_processors = {
  # Locale-aware currency formatting
  price: ->(value, metadata = {}) {
    locale = metadata[:_locale] || I18n.locale
    case locale.to_s
    when 'cs'
      "#{value.to_f.round} Kč"
    when 'en'
      "$#{value.to_f.round}"
    else
      value.to_s
    end
  },
  
  # Custom aperture formatting
  aperture: ->(value, metadata = {}) {
    return nil unless value
    "Custom: f/#{value.to_f}"
  },
  
  # Process custom field with validation
  internal_photo_id: ->(value, metadata = {}) {
    return nil unless value
    # Ensure it matches your ID format (example: PH123456)
    value.to_s =~ /^PH\d{6,}$/ ? value.to_s : nil
  }
}
```

### Custom Business Logic

Add custom methods to your Image model using the unified `mapped_metadata` API:

```ruby
# app/models/folio/file/image.rb (or via decorator)
class Folio::File::Image
  # Custom business methods using mapped_metadata
  def watermark_required?
    !internal_photo? && !creative_commons?
  end
  
  def internal_photo?
    mapped_metadata[:credit_line]&.include?("MyCompany") || 
    mapped_metadata[:internal_photo_id].present?
  end
  
  def creative_commons?
    mapped_metadata[:copyright_notice]&.include?("Creative Commons") ||
    mapped_metadata[:usage_terms]&.include?("CC")
  end
  
  def display_headline
    headline = mapped_metadata[:headline]
    headline.present? ? "[Custom] #{headline}" : nil
  end
  
  def photographer_info
    {
      name: mapped_metadata[:creator]&.first,
      credit: mapped_metadata[:credit_line],
      copyright: mapped_metadata[:copyright_notice]
    }
  end
end
```

### Known Providers Detection

Configure automatic source detection for photo agencies:

```ruby
Rails.application.config.folio_image_metadata_known_providers = [
  {
    name: "ČTK",
    patterns: [/ČTK/i, /Czech News Agency/i, /Česká tisková kancelář/i]
  },
  {
    name: "Getty Images", 
    patterns: [/Getty/i, /Getty Images/i]
  }
]
```

## UTF-8 Charset Handling

### Problem Resolution

IPTC metadata containing Czech/Slovak characters often displays as mojibake due to charset encoding issues. The system resolves this by:

```ruby
# Configuration forcing UTF-8 interpretation
config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"]

# Processed UTF-8 data stored for clean display
def store_processed_metadata_for_getters(mapped_data)
  self.file_metadata['creator'] = mapped_data[:creator] if mapped_data[:creator].present?
  self.file_metadata['headline'] = mapped_data[:headline] if mapped_data[:headline].present?
end
```

**Result**: Converts `"ÄŒTK / Å imÃ¡nek VÃ­t"` → `"ČTK / Šimánek Vít"`

## IPTC Standards Compliance

### Supported Standards

- **EXIF**: Technical camera metadata (ISO, aperture, GPS)
- **IPTC Core**: Descriptive fields (creator, headline, keywords)
- **IPTC Extension**: Advanced fields (persons shown, locations)
- **XMP**: Modern metadata container format
- **Dublin Core**: Standard descriptive elements

### Field Mapping with Priorities

The system maps metadata using international IPTC standards with intelligent fallbacks:

```ruby
# Creator mapping with fallbacks
XMP-dc:Creator → IPTC:By-line → Artist → author field

# Headline mapping  
XMP-photoshop:Headline → IPTC:Headline → headline field

# Keywords handling
XMP-dc:Subject → IPTC:Keywords → merged into tag_list

# Technical metadata
ExifIFD:FocalLength → "35mm" (formatted)
ExifIFD:Flash → "Nepoužit" (localized)
```

## API Integration

### Console File Serializer

The serializer exposes metadata fields and includes dynamic metadata from JSON:

```ruby
# app/serializers/folio/console/file_serializer.rb
class Folio::Console::FileSerializer
  # Standard database fields
  attribute :headline
  attribute :author
  attribute :description
  attribute :capture_date
  attribute :gps_latitude
  attribute :gps_longitude
  attribute :file_metadata_extracted_at
  
  # Dynamic metadata from JSON (for frontend consumption)
  attribute :dynamic_metadata do |object|
    object.respond_to?(:file_metadata) ? object.file_metadata || {} : {}
  end
  
  # Image-specific accessors (only for Image files)
  attribute :creator_list do |object|
    object.respond_to?(:creator_list) ? object.creator_list : []
  end
  
  attribute :keywords_list do |object|
    object.respond_to?(:keywords_list) ? object.keywords_list : []
  end
end
```

### Extraction Endpoint

```ruby
# POST /console/api/file/images/:id/extract_metadata
# app/controllers/concerns/folio/console/api/file_controller_base.rb
def extract_metadata
  return render(json: { error: "Not supported for this file type" }, status: 422) unless folio_console_record.respond_to?(:extract_metadata!)

  # Force re-extraction synchronously for immediate UI feedback
  if folio_console_record.respond_to?(:extract_metadata!)
    # Run synchronous extraction with force flag
    folio_console_record.extract_metadata!(force: true, user_id: Folio::Current.user&.id)
    folio_console_record.reload

    # Broadcast for live UI update (MessageBus JSON payload)
    broadcast_metadata_extracted(folio_console_record)

    render_record(folio_console_record, Folio::Console::FileSerializer)
  end
end
```

## Performance Considerations

### Asynchronous Processing

- Metadata extraction runs in background jobs via `ExtractMetadataJob`
- UI updates automatically via MessageBus without page reload
- Large files don't block upload process

### Caching Strategy

- Raw metadata stored permanently in JSON
- Processed data cached for JSON getters
- Essential fields indexed for database queries
- Locale-specific extractor instances cached per request

## Testing Framework

```ruby
# test/models/folio/image_test.rb
class Folio::File::ImageTest < ActiveSupport::TestCase
  test "extracts metadata via service" do
    raw_metadata = {
      "XMP-dc:Creator" => ["John Doe"],
      "XMP-photoshop:Headline" => "Test Headline"
    }

    image = create(:folio_file_image)
    
    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
    
    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }
    
    # Update database fields
    mapped_data.each do |field, value|
      next if value.blank?
      if image.respond_to?("#{field}=") && image.send(field).blank?
        image.send("#{field}=", value)
      end
    end
    
    image.save!
    image.reload

    assert_equal "Test Headline", image.headline
    assert_equal ["John Doe"], image.creator_list
  end
  
  test "preserves existing user data during extraction" do
    image = create(:folio_file_image, author: "Jane Smith", headline: "Existing headline")
    
    # Extraction should not overwrite existing data
    raw_metadata = { "XMP-dc:Creator" => ["New Author"], "XMP-photoshop:Headline" => "New headline" }
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
    
    # Only update blank fields
    mapped_data.each do |field, value|
      next if value.blank?
      if image.respond_to?("#{field}=") && image.send(field).blank?
        image.send("#{field}=", value)
      end
    end
    
    image.save!
    
    assert_equal "Jane Smith", image.author  # Preserved
    assert_equal "Existing headline", image.headline  # Preserved
  end
  
  test "handles non-image files gracefully" do
    document = create(:folio_file_document)
    assert_not document.respond_to?(:creator_list)
    assert_not document.respond_to?(:extract_metadata!)
  end
end
```

## Example Configuration

Here's a complete example configuration for a Czech publishing house:

```ruby
# config/initializers/folio_image_metadata.rb
Rails.application.configure do
  # Basic setup
  config.folio_image_metadata_extraction_enabled = true
  config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"]
  
  # Czech language priority
  config.folio_image_metadata_locale_priority = [:cs, :en, "x-default"]
  
  # Auto-population rules
  config.folio_image_metadata_populate_user_fields = {
    headline: :headline,
    author: :creator,
    description: :description,
    attribution_copyright: :copyright_notice,
    capture_date: :capture_date
  }
  
  # Merge keywords and skip licence auto-population
  config.folio_image_metadata_merge_keywords_to_tags = true
  config.folio_image_metadata_skip_population_fields = ["attribution_licence"]
  
  # Czech agency detection
  config.folio_image_metadata_known_providers = [
    { name: "ČTK", patterns: [/ČTK/i, /Czech News Agency/i] },
    { name: "Profimedia", patterns: [/Profimedia/i, /ProfiMedia/i] },
    { name: "MAFRA", patterns: [/MAFRA/i, /iDNES/i] }
  ]
  
  # Custom business logic
  config.folio_image_metadata_field_processors = {
    copyright_notice: ->(value, metadata = {}) {
      result = value.to_s
      
      # Add publisher copyright if missing
      if result.blank?
        "© #{Date.current.year} Vydavatelství s.r.o."
      elsif !result.include?("Vydavatelství")
        "#{result} | Vydavatelství"
      else
        result
      end
    }
  }
end
```

---

## Implementation Status

### Core Functionality ✅
- JSON metadata storage in `file_metadata` column
- UTF-8 charset handling prevents mojibake in Czech/Slovak content
- Image-specific metadata extraction via `Folio::File::Image` only
- Clean service architecture with `Folio::Metadata::ExtractionService` and `IptcFieldMapper`
- Simplified metadata accessors reading directly from JSONB
- Keywords merging into existing tag_list system
- Configurable and extensible via Rails.application.config

### User Interface ✅
- Read-only metadata display in organized tables (Descriptive, Technical, Rights, Location)
- User form fields remain fully editable above metadata display
- Live UI updates via MessageBus without page reload
- Automatic I18n integration for labels and formatted values
- React state consistency between file switches

### Backend Integration ✅
- Migration adds only 8 essential metadata columns (minimal schema impact)
- Service-based architecture with clear separation of concerns
- Asynchronous extraction via background jobs with optional user context
- Manual extraction via `extract_metadata!(force: true, user_id:)` endpoint
- Keywords merge into existing tag_list system when configured
- MessageBus broadcasting for live console updates with targeted user messaging