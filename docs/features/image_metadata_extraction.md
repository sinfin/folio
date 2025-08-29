# Image Metadata Extraction

## Overview

This feature enables automatic extraction and mapping of EXIF/IPTC/XMP metadata from uploaded images to database fields and JSON storage, following international IPTC standards for content management systems.

The system provides a clean, extensible architecture with full I18n support and intelligent fallbacks for all file types.

## Architecture

The metadata system follows clean architecture principles with clear separation of concerns:

```ruby
# Image-specific metadata extraction
Folio::File (base model - no metadata extraction)
└── Folio::File::Image (Image files only)
    └── include Folio::ImageMetadataExtraction
        ├── IPTC/EXIF metadata extraction
        └── Extractor service delegation

# Service layer for business logic
Folio::Metadata::IptcFieldMapper (mapping & formatting)
├── FIELD_MAPPINGS: field priorities with fallbacks
├── COMPLEX_FIELD_PROCESSORS: formatting logic
└── I18n support: locale-aware processing

Folio::Metadata::Extractor (configurable business logic)
├── get_field(field_name, locale: nil)
├── method_missing: dynamic delegation
└── Custom business methods
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
# Triggered after file creation
after_commit :extract_image_metadata_async, on: :create, if: :should_extract_metadata?

# Background job extracts metadata with UTF-8 charset
def extract_raw_metadata_with_exiftool(image)
  command = ["exiftool", "-j", "-G1", "-struct", "-n", "-charset", "iptc=utf8", file_path]
  # Returns: { "XMP-dc:Creator" => ["John Doe"], "IPTC:Headline" => "News", ... }
end
```

### 2. Field Mapping and Processing

The `IptcFieldMapper` handles complex field mapping with fallbacks and I18n support:

```ruby
# Maps raw ExifTool output to application fields
mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata, locale: :cs)
# => { headline: "News Photo", creator: ["John Doe"], flash: "Nepoužit", ... }

# Auto-populates only blank user fields
def populate_user_fields_from_mapped_data(file, mapped_data)
  file.headline = mapped_data[:headline] if file.headline.blank?
  file.author = Array(mapped_data[:creator]).join(", ") if file.author.blank?
  file.capture_date = mapped_data[:capture_date] if file.capture_date.blank?
  # Keywords merged into existing tag_list system
end
```

### 3. Dynamic Metadata Access

All file types have consistent metadata API through the unified `MetadataExtraction` concern:

```ruby
# Image files - full functionality via extractor service
image.headline_from_metadata  # => "Actual headline"
image.creator                 # => ["John Doe", "Jane Smith"]
image.flash                   # => "Nepoužit" (localized)
image.camera_make            # => "Canon"

# Non-image files - intelligent fallbacks
document.headline_from_metadata  # => nil
document.creator                 # => []
video.flash                      # => nil
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

### Custom Extractor Service

Replace the entire extraction service with your own business logic:

```ruby
# app/services/my_app/custom_metadata_extractor.rb
class MyApp::CustomMetadataExtractor < Folio::Metadata::Extractor
  def headline
    # Your custom headline logic
    result = super
    result&.prepend("[Custom] ")
  end
  
  def watermark_required?
    # Custom business method
    !internal_photo? && !creative_commons?
  end
  
  def internal_photo?
    credit_line&.include?("MyCompany") || 
    get_field(:internal_photo_id).present?
  end
  
  def creative_commons?
    copyright_notice&.include?("Creative Commons") ||
    usage_terms&.include?("CC")
  end
end

# config/initializers/folio_image_metadata.rb  
Rails.application.config.folio_image_metadata_extractor_class = MyApp::CustomMetadataExtractor
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

The serializer automatically exposes all metadata fields:

```ruby
# app/serializers/folio/console/file_serializer.rb
class Folio::Console::FileSerializer
  # Standard fields (work for all file types via concern)
  attribute :headline_from_metadata
  attribute :creator
  attribute :camera_make
  attribute :flash  # Automatically localized
  attribute :capture_date_from_metadata
  attribute :file_metadata_extracted_at
  
  # Custom fields (if configured)
  attribute :internal_photo_id do |object|
    object.respond_to?(:metadata_extractor) ? 
      object.metadata_extractor.get_field(:internal_photo_id) : nil
  end
end
```

### Extraction Endpoint

```ruby
# POST /console/api/file/images/:id/extract_metadata
def extract_metadata
  folio_console_record.extract_image_metadata_sync
  render_record(folio_console_record, Folio::Console::FileSerializer)
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
# test/models/folio/file/image_metadata_extraction_test.rb
class MetadataExtractionTest < ActiveSupport::TestCase
  test "extracts author from IPTC creator field" do
    image = create_image_with_metadata("XMP-dc:Creator" => ["John Doe"])
    assert_equal "John Doe", image.author
  end
  
  test "preserves existing user data" do
    image = create(:folio_file_image, author: "Jane Smith")
    image.extract_image_metadata_sync
    assert_equal "Jane Smith", image.author
  end
  
  test "handles non-image files gracefully" do
    document = create(:folio_file_document)
    assert_equal [], document.creator
    assert_nil document.headline_from_metadata
  end
  
  test "respects I18n locale" do
    image = create_image_with_metadata("ExifIFD:Flash" => "0")
    
    I18n.with_locale(:cs) do
      assert_equal "Nepoužit", image.flash
    end
    
    I18n.with_locale(:en) do
      assert_equal "Not used", image.flash
    end
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
- Unified `MetadataExtraction` concern for all file types
- Clean service architecture with `IptcFieldMapper` and `Extractor`
- Full I18n support with locale-aware processing
- Dynamic delegation with intelligent fallbacks
- Configurable and extensible via Rails.application.config

### User Interface ✅
- Read-only metadata display in organized tables (Descriptive, Technical, Rights, Location)
- User form fields remain fully editable above metadata display
- Live UI updates via MessageBus without page reload
- Automatic I18n integration for labels and formatted values
- React state consistency between file switches

### Backend Integration ✅
- Migration adds only 5 essential columns (minimal schema impact)
- Keywords merge into existing tag_list system
- Asynchronous and synchronous extraction methods available
- MessageBus broadcasting for live console updates
- Locale-aware caching and performance optimization