# Image Metadata Extraction

## Overview

This feature enables automatic extraction and mapping of EXIF/IPTC/XMP metadata from uploaded images to database fields and JSON storage, following international IPTC standards for content management systems.

The system provides a clean, extensible architecture with full I18n support and intelligent fallbacks for image files.

## Architecture

The metadata system follows clean architecture principles with clear separation of concerns:

- **[`app/models/folio/file/image.rb`](../app/models/folio/file/image.rb)** - Image model with metadata extraction callbacks and simplified accessors
- **[`app/services/folio/metadata/extraction_service.rb`](../app/services/folio/metadata/extraction_service.rb)** - Core extraction logic and database field updates
- **[`app/services/folio/metadata/iptc_field_mapper.rb`](../app/services/folio/metadata/iptc_field_mapper.rb)** - IPTC field mapping, encoding fixes, and I18n formatting
- **[`app/jobs/folio/metadata/extraction_job.rb`](../app/jobs/folio/metadata/extraction_job.rb)** - Background job with MessageBus broadcasting
- **[`config/initializers/folio_image_metadata.rb`](../config/initializers/folio_image_metadata.rb)** - Configuration and field mappings

### Database Schema

The system uses a hybrid approach combining database columns for essential fields with JSON storage for comprehensive metadata preservation:

**Essential database columns** (user-editable + indexable):
- `headline`, `author`, `description`, `alt` - Core descriptive fields
- `attribution_source`, `attribution_copyright` - Rights management
- `capture_date` - Photo creation timestamp  
- `gps_latitude`, `gps_longitude` - GPS coordinates

**JSON metadata storage** (complete preservation):
- `file_metadata` - Raw EXIF/IPTC/XMP data + processed values
- `file_metadata_extracted_at` - Extraction timestamp

> See complete schema in [`app/models/folio/file/image.rb`](../app/models/folio/file/image.rb) (lines 64-103)

## Setup and Configuration

The metadata extraction system is pre-configured with sensible defaults. Key configuration options:

- `folio_image_metadata_extraction_enabled` - Enable/disable metadata extraction (default: true)
- `folio_image_metadata_exiftool_options` - ExifTool command options for extraction
- `folio_image_metadata_merge_keywords_to_tags` - Merge extracted keywords into tag system
- `folio_image_metadata_locale_priority` - Language priority for multi-language metadata

> Complete configuration with all options available in [`config/initializers/folio_image_metadata.rb`](../config/initializers/folio_image_metadata.rb)

## Metadata Extraction Process

### Automatic Extraction

When an image is uploaded, metadata extraction occurs automatically:

1. **Upload** - Image uploaded via Folio console  
2. **Callback** - `after_commit :extract_metadata_async` triggers extraction
3. **Background Job** - `Folio::Metadata::ExtractionJob` processes metadata
4. **Field Mapping** - `Folio::Metadata::IptcFieldMapper` maps EXIF/IPTC/XMP to database fields
5. **Storage** - Raw metadata stored in JSON, essential fields in database columns
6. **UI Update** - MessageBus broadcasts completion for live UI refresh

### Dynamic Access

Image files provide intelligent metadata accessors with fallbacks:

```ruby
# Database field takes priority, falls back to extracted metadata
image.title         # headline → file_metadata["headline"]
image.caption       # description → file_metadata["description"]  
image.mapped_metadata[:creator]  # Formatted IPTC data
```

> **Implementation Details**: See [`app/models/folio/file/image.rb`](../app/models/folio/file/image.rb) and [`app/services/folio/metadata/extraction_service.rb`](../app/services/folio/metadata/extraction_service.rb)

## User Interface

The Folio console provides a comprehensive file metadata editor with:

**Editable Fields**: Headline, Description, Alt text, Author, Attribution fields, Default crop settings

**Read-Only Metadata Display**: Organized tables showing Descriptive, Technical, Rights, and Location metadata

**Live Updates**: React components receive real-time extraction completion via MessageBus broadcasting

**I18n Support**: All labels automatically localized via Rails translations

## Advanced Customization

### Custom Field Mappings

Override default field sources or add new fields via configuration:

```ruby
# config/initializers/folio_image_metadata.rb
Rails.application.config.folio_image_metadata_field_mappings = {
  headline: ["MyApp:CustomHeadline", "XMP-photoshop:Headline", "IPTC:Headline"],
  internal_photo_id: ["MyApp:PhotoID", "XMP-myapp:PhotoID"]
}
```

### Custom Field Processors

Add custom formatting and business logic with I18n support:

```ruby
Rails.application.config.folio_image_metadata_field_processors = {
  aperture: ->(value) { value ? "f/#{value.to_f}" : nil }
}
```

### Known Providers Detection

Configure automatic source detection for photo agencies:

```ruby
Rails.application.config.folio_image_metadata_known_providers = [
  { name: "ČTK", patterns: [/ČTK/i, /Czech News Agency/i] },
  { name: "Getty Images", patterns: [/Getty/i, /Getty Images/i] }
]
```

> Complete customization examples in [`config/initializers/folio_image_metadata.rb`](../config/initializers/folio_image_metadata.rb)

## Advanced Encoding & IPTC-IIM Compliance

The system provides sophisticated encoding handling that respects IPTC-IIM standards and automatically repairs corrupted text:

### Encoding Features

- **IPTC-IIM CodedCharacterSet compliance** - Respects field 1:90 encoding declarations
- **Mojibake detection and repair** - Fixes double-encoded and corrupted text
- **Quality scoring** - Only updates database fields when new values have better encoding quality
- **Multi-charset fallbacks** - Tries multiple encoding candidates (Windows-1250, ISO-8859-2, etc.)

### Example Repairs

- `"ƒåTK / Taneƒçek David"` → `"ČTK / Taneček David"` (correct Czech characters)
- `"soutÄž v pojÃ­dÃ¡nÃ­"` → `"soutěž v pojídání"` (proper diacritics)

> **Implementation Details**: See [`app/services/folio/metadata/iptc_field_mapper.rb`](../app/services/folio/metadata/iptc_field_mapper.rb) (lines 812-940)

## IPTC Standards Compliance

### Supported Standards

- **EXIF**: Technical camera metadata (ISO, aperture, GPS)
- **IPTC Core**: Descriptive fields (creator, headline, keywords)
- **IPTC Extension**: Advanced fields (persons shown, locations)
- **XMP**: Modern metadata container format
- **Dublin Core**: Standard descriptive elements

### Field Mapping

The system maps metadata using international IPTC standards with intelligent fallbacks (XMP → IPTC → EXIF precedence).

> **Field Mappings**: See complete mapping table in [`app/services/folio/metadata/iptc_field_mapper.rb`](../app/services/folio/metadata/iptc_field_mapper.rb) (lines 10-263)

## API Integration

Manual metadata extraction is available via:

```
POST /console/api/files/:id/extract_metadata
```

Forces synchronous re-extraction with immediate UI feedback via MessageBus broadcasting.

> **Implementation**: See [`app/controllers/concerns/folio/console/api/file_controller_base.rb`](../app/controllers/concerns/folio/console/api/file_controller_base.rb) (lines 91-107)

## Performance Considerations

- **Asynchronous Processing**: Metadata extraction runs in background jobs via `Folio::Metadata::ExtractionJob`
- **Caching Strategy**: Raw metadata stored permanently in JSON, essential fields indexed for database queries
- **Non-blocking Uploads**: Large files don't block upload process
- **Live UI Updates**: MessageBus provides real-time extraction completion feedback

## Testing Framework

Comprehensive test coverage includes:

- **Service Integration**: Complete extraction pipeline with real metadata samples
- **Field Mapping**: IPTC/XMP to database field mapping accuracy
- **I18n Support**: Localized formatting and charset handling
- **Error Handling**: Safe handling of metadata-less images and extraction failures

**Test Files**:
- [`test/models/folio/image_test.rb`](../test/models/folio/image_test.rb)
- [`test/models/folio/image_metadata_samples_test.rb`](../test/models/folio/image_metadata_samples_test.rb)
- [`test/models/folio/file/image_metadata_charset_test.rb`](../test/models/folio/file/image_metadata_charset_test.rb)
- [`test/integration/folio/image_metadata_extraction_integration_test.rb`](../test/integration/folio/image_metadata_extraction_integration_test.rb)