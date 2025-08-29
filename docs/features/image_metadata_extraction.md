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
    ├── Delegates to ExtractionJob (asynchronous processing)
    └── Delegates to ExtractionService (synchronous processing)

# Background job layer for asynchronous processing
Folio::Metadata::ExtractionJob (ActiveJob background processing)
├── queue_as :slow - uses slow queue for heavy operations
├── perform(image, force: false, user_id: nil) - job entry point
├── MessageBus broadcasting for live console UI updates
└── Delegates to ExtractionService for actual processing

# Service layer for business logic
Folio::Metadata::ExtractionService (core extraction logic)
├── extract!(force: false, user_id: nil) - main extraction method
├── should_extract?(image) - validation logic
├── Intelligent database field updates with quality scoring
└── Delegates to IptcFieldMapper for field mapping

Folio::Metadata::IptcFieldMapper (mapping & formatting)
├── FIELD_MAPPINGS: field priorities with fallbacks
├── COMPLEX_FIELD_PROCESSORS: formatting logic
├── IPTC-IIM charset compliance (1:90 CodedCharacterSet)
├── Mojibake detection and repair with ICU fallbacks
├── Regex constants: CZECH_CHARS_REGEX, MOJIBAKE_PATTERNS_REGEX
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

### 1. Basic Configuration

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
# Main extraction method with intelligent updates
def extract!(force: false, user_id: nil)
  metadata = @image.file.metadata  # Uses Dragonfly with UTF-8 charset
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

  # Update database fields with intelligent quality scoring
  update_database_fields(image, mapped_data)

  # Handle tags separately (with tenant-safe filtering)
  handle_tags_separately(image, mapped_data)
end
```

### 3. Dynamic Metadata Access

**Principle**: Image files have simplified metadata accessors that intelligently fallback between database fields and extracted JSON metadata.

```ruby
# Intelligent fallback: DB field → file_metadata JSON
def title
  headline.presence || file_metadata&.dig("headline")
end
```

**Key Features**:
- Database fields (user-editable) take priority over extracted metadata
- JSONB field preserves complete raw and processed metadata
- Only `Folio::File::Image` has metadata extraction (documents/videos don't)
- Clean API: `image.mapped_metadata[:creator]`, `image.mapped_metadata[:keywords]`, `image.file_metadata`

> **Implementation Details**: See [`app/models/folio/file/image.rb`](https://github.com/sinfin/folio/blob/master/app/models/folio/file/image.rb) for complete accessor methods.

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

## Advanced Encoding & IPTC-IIM Compliance

### Intelligent Mojibake Detection and Repair

The system provides sophisticated encoding handling that respects IPTC-IIM standards and automatically repairs corrupted text:

```ruby
# 1. IPTC-IIM CodedCharacterSet (1:90) compliance
# When 1:90 = "UTF8" or "%G" (ESC % G), decode all IPTC fields as UTF-8
# When 1:90 missing, default is ISO-8859-1

# 2. Regex constants for consistent pattern matching
CZECH_CHARS_REGEX = /[ěščřžýáíéúůťďňóĚŠČŘŽÝÁÍÉÚŮŤĎŇÓ]/
MOJIBAKE_PATTERNS_REGEX = /(Ã.|Â.|â..|√|≈|ƒ|�|Ä|Å¡|Å¾|Å¯|Å™|Äœ)/

# 3. Quality scoring for intelligent updates
def score_cs(text)
  text.scan(CZECH_CHARS_REGEX).size * 3 - 
  text.scan(MOJIBAKE_PATTERNS_REGEX).size * 6 - 
  [text.count("?") - 2, 0].max
end

# 4. Multi-fallback encoding repair
def unmojibake(str, metadata = {})
  coded_charset = metadata["IPTC:CodedCharacterSet"]
  
  case coded_charset&.upcase
  when "UTF8", "%G"  # ESC % G sequence
    needs_encoding_fix?(str) ? fix_utf8_mojibake(str) : str
  when nil, "", "ISO-8859-1"
    # Try repair or ISO-8859-1 conversion with quality check
  else
    # Handle declared charsets (Windows-1250, etc.)
  end
end
```

### Problem Resolution Examples

**Before**: `"ƒåTK / Taneƒçek David"` (mojibake from double-encoding)  
**After**: `"ČTK / Taneček David"` (correct Czech characters)

**Before**: `"soutÄž v pojÃ­dÃ¡nÃ­"` (ISO-8859-1 → UTF-8 mojibake)  
**After**: `"soutěž v pojídání"` (proper diacritics)

### Intelligent Database Updates

The system only updates database fields when the new value has better encoding quality:

```ruby
# Compare encoding quality before updating
current_quality = IptcFieldMapper.score_cs(current_value.to_s)
new_quality = IptcFieldMapper.score_cs(new_value.to_s)

if new_quality > current_quality
  Rails.logger.info "Updating #{field} due to better encoding quality"
  image.send("#{field}=", new_value)
end
```

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

- Metadata extraction runs in background jobs via `Folio::Metadata::ExtractionJob`
- UI updates automatically via MessageBus without page reload
- Large files don't block upload process

### Caching Strategy

- Raw metadata stored permanently in JSON
- Processed data cached for JSON getters
- Essential fields indexed for database queries
- Locale-specific extractor instances cached per request

## Testing Framework

**Testing Approach**: Comprehensive test coverage for metadata extraction, field mapping, and error handling scenarios.

**Key Test Areas**:
- **Service Integration**: Tests complete extraction pipeline with real metadata
- **Field Mapping**: Validates IPTC/XMP to database field mapping accuracy  
- **I18n Support**: Ensures localized formatting (flash: "Nepoužit", white_balance: "Ruční")
- **Error Handling**: Safe handling of metadata-less images and multiple extractions
- **Force Parameter**: Respects `force: true/false` for re-extraction control

> **Complete Test Suite**: See [`test/models/folio/image_test.rb`](https://github.com/sinfin/folio/blob/master/test/models/folio/image_test.rb) and [`test/services/folio/metadata/`](https://github.com/sinfin/folio/tree/master/test/services/folio/metadata) for full test implementations.

## Example Configuration

**Configuration Principle**: Enable extraction, set locale priority, configure field mappings, and define provider patterns.

**Key Configuration Areas**:
- **Basic Setup**: `folio_image_metadata_extraction_enabled = true`
- **ExifTool Options**: `["-G1", "-struct", "-n", "-charset", "iptc=utf8"]`
- **Locale Priority**: `[:cs, :en, "x-default"]` for Czech sites
- **Field Auto-Population**: Map extracted metadata to database columns
- **Provider Detection**: Regex patterns for Getty Images, Shutterstock, etc.

> **Complete Configuration Examples**: See [`config/initializers/folio_image_metadata.rb`](https://github.com/sinfin/folio/blob/master/config/initializers/folio_image_metadata.rb) for full configuration options.