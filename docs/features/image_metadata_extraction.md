# Image Metadata Extraction

## Overview

This feature enables automatic extraction and mapping of EXIF/IPTC/XMP metadata from uploaded images to database fields and JSON storage, following international IPTC standards for content management systems.

## Architecture

### JSON-Based Metadata Storage

The system uses a hybrid approach combining database columns for user-editable fields with JSON storage for comprehensive metadata preservation:

```ruby
# Core database columns (user-editable)
headline: string              # Editorial title/headline
author: string               # Creator/photographer  
description: text            # Caption/description
alt: string                  # Accessibility text
attribution_source: string   # Credit line/agency
attribution_copyright: string # Copyright notice
capture_date: datetime       # Photo creation timestamp
gps_latitude: decimal        # GPS coordinates
gps_longitude: decimal       # GPS coordinates

# JSON metadata storage (complete preservation)
file_metadata: json          # Raw EXIF/IPTC/XMP data
file_metadata_extracted_at: datetime # Extraction timestamp
```

### Core Components

**Backend Services:**
- `Folio::ImageMetadataExtraction` - Main extraction workflow concern
- `Folio::Metadata::IptcFieldMapper` - IPTC field mapping with fallbacks
- `Folio::ExtractMetadataJob` - Background processing with MessageBus broadcasting
- `Folio::File::Image` - Model with JSON metadata getters

**Frontend Components:**
- `ReadOnlyMetadataDisplay` - React component for metadata tables
- `FileModal` - Modal with MessageBus listener for live updates
- `FileModalFile` - Integration of metadata display with user forms

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

### 2. Field Mapping and Population

The `IptcFieldMapper` handles complex field mapping with fallbacks:

```ruby
# Maps raw ExifTool output to application fields
mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
# => { headline: "News Photo", creator: ["John Doe"], capture_date: Time.parse(...) }

# Auto-populates only blank user fields
def populate_user_fields_from_mapped_data(file, mapped_data)
  file.headline = mapped_data[:headline] if file.headline.blank?
  file.author = Array(mapped_data[:creator]).join(", ") if file.author.blank?
  file.capture_date = mapped_data[:capture_date] if file.capture_date.blank?
  # Keywords merged into existing tag_list system
end
```

### 3. JSON Getters for Display

Metadata access through JSON getters preserves all extracted data:

```ruby
def creator
  # Prioritizes processed UTF-8 data over raw metadata
  file_metadata&.dig("creator") || 
  file_metadata&.dig("XMP-dc:Creator") || 
  file_metadata&.dig("IPTC:By-line") || []
end

def camera_make
  file_metadata&.dig("Make")
end

def copyright_notice
  file_metadata&.dig("XMP-photoshop:Copyright")
end
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
- **Descriptive**: Headline, Creator(s), Keywords, Caption Writer
- **Technical**: Camera info, Capture date, GPS, Dimensions
- **Rights**: Copyright, Usage terms, Rights URL
- **Location**: Created/Shown locations, City, Country

### Live Updates

React components receive real-time updates via MessageBus:

```javascript
// MessageBus listener for metadata extraction completion
if (msg.type === 'Folio::File::MetadataExtracted' && msg.file) {
  const updatedFile = { ...this.props.fileModal.file, attributes: { ...msg.file.attributes }}
  this.props.dispatch(updatedFileModalFile(updatedFile))
}
```

## Configuration

### Basic Setup

```ruby
# config/initializers/folio_image_metadata.rb
Rails.application.config.tap do |config|
  config.folio_image_metadata_extraction_enabled = true
  config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"]
  
  # Field auto-population rules
  config.folio_image_metadata_populate_user_fields = {
    headline: :headline,
    author: :creator,
    description: :description,
    attribution_copyright: :copyright_notice,
    capture_date: :capture_date
  }
end
```

### Advanced Options

```ruby
# Skip auto-population for specific fields
config.folio_image_metadata_skip_population_fields = ["attribution_licence"]

# Merge keywords into tag_list system
config.folio_image_metadata_merge_keywords_to_tags = true

# Language priority for multi-language metadata
config.folio_image_metadata_locale_priority = [:cs, :en, "x-default"]
```

## Database Migration

Minimal schema changes required:

```ruby
class AddEssentialMetadataFieldsToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :headline, :string
    add_column :folio_files, :capture_date, :datetime
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :file_metadata_extracted_at, :datetime
    
    add_index :folio_files, :capture_date
    add_index :folio_files, [:gps_latitude, :gps_longitude]
  end
end
```

## IPTC Standards Compliance

### Supported Standards

- **EXIF**: Technical camera metadata (ISO, aperture, GPS)
- **IPTC Core**: Descriptive fields (creator, headline, keywords)
- **IPTC Extension**: Advanced fields (persons shown, locations)
- **XMP**: Modern metadata container format
- **Dublin Core**: Standard descriptive elements

### Field Mapping

The system maps metadata using international IPTC standards:

```ruby
# Creator mapping with fallbacks
XMP-dc:Creator → IPTC:By-line → Artist → author field

# Headline mapping  
XMP-photoshop:Headline → IPTC:Headline → headline field

# Keywords handling
XMP-dc:Subject → IPTC:Keywords → merged into tag_list
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

## Testing Framework

```ruby
# test/models/folio/file/image_metadata_extraction_test.rb
class ImageMetadataExtractionTest < ActiveSupport::TestCase
  test "extracts author from IPTC creator field" do
    image = create_image_with_metadata("XMP-dc:Creator" => ["John Doe"])
    assert_equal "John Doe", image.author
  end
  
  test "preserves existing user data" do
    image = create(:folio_file_image, author: "Jane Smith")
    image.extract_image_metadata_sync
    assert_equal "Jane Smith", image.author
  end
end
```

## Internationalization

### Multi-Language Support

- Czech/English translations for UI labels
- UTF-8 charset handling for Czech/Slovak content
- Locale priority configuration for multi-language metadata

### Translation Keys

```yaml
# config/locales/console/file.cs.yml
cs:
  folio:
    console:
      file:
        descriptive_metadata: 'Popisná metadata'
        technical_metadata: 'Technická metadata'
        metadata:
          headline: 'Titulek'
          creator: 'Autor'
```

## API Integration

### Console File Serializer

```ruby
# app/serializers/folio/console/file_serializer.rb
class Folio::Console::FileSerializer
  attribute :headline_from_metadata
  attribute :creator
  attribute :camera_make
  attribute :capture_date
  attribute :file_metadata_extracted_at
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

---

## Implementation Status

### Core Functionality
- ✅ JSON metadata storage in `file_metadata` column
- ✅ UTF-8 charset handling prevents mojibake in Czech/Slovak content
- ✅ Asynchronous extraction via `ExtractMetadataJob`
- ✅ Auto-population of blank user fields only
- ✅ IptcFieldMapper with fallback chains and special processors
- ✅ JSON getters for metadata display without database schema explosion

### User Interface
- ✅ Read-only metadata display in organized tables (Descriptive, Technical, Rights, Location)
- ✅ User form fields remain fully editable above metadata display
- ✅ Live UI updates via MessageBus without page reload
- ✅ Metadata always visible after tags section
- ✅ React state consistency between file switches
- ✅ Czech/English i18n support for metadata labels

### Backend Integration
- ✅ Migration adds only essential columns (5 total vs 30+ in original plan)
- ✅ Keywords merge into existing tag_list system
- ✅ Synchronous and asynchronous extraction methods available
- ✅ MessageBus broadcasting for live console updates
- ✅ UTF-8 processed data stored for JSON getters

### Testing & Quality
- ⚠️ Comprehensive test coverage for extraction logic
- ⚠️ Local fixture files instead of S3 dependencies
- ⚠️ Re-extraction testing for existing files

### Documentation & Migration
- ✅ Implementation guide with component references
- ✅ Configuration examples and API documentation
- ⚠️ Migration guide for existing installations
- ⚠️ Bulk re-extraction tools for legacy files

### Outstanding Issues
- ⚠️ Webpack dev server CORS configuration
- ⚠️ FriendlyId routing conflicts with API endpoints
- ⚠️ Performance monitoring for large file extraction