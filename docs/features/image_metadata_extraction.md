# Image Metadata Extraction Feature Specification

## Overview

This feature enables automatic extraction and mapping of EXIF/IPTC/XMP metadata from uploaded images to database fields following **international IPTC standards**, improving SEO and simplifying content management.

## IPTC / EXIF / XMP Metadata Standards

Image metadata in global agencies follows international standards. The key is to **avoid vendor-specific field names** and rely on the standardized **IPTC Photo Metadata Standard**, mapped consistently across **EXIF** and **XMP**.

### Core Standards

- **EXIF (Exchangeable Image File Format)**  
  Technical metadata recorded by the camera (timestamp, aperture, shutter speed, GPS, orientation).  
  Maintained by **JEITA**.  

- **IPTC Photo Metadata Standard**  
  Defines descriptive and rights-related metadata (creator, caption, keywords, rights, locations, persons).  
  Includes **IPTC Core** (basic descriptive fields) and **IPTC Extension** (expanded fields like persons shown, detailed locations).  
  Can be embedded in legacy **IPTC-IIM** format or modern **XMP**.

- **XMP (Extensible Metadata Platform)**  
  Open standard by Adobe, based on RDF/XML.  
  Recommended container for IPTC, Dublin Core (dc:), Photoshop (photoshop:), XMP Rights (xmpRights:), and other namespaces.

### Authoritative Resources

- 📄 [IPTC Photo Metadata Standard](https://iptc.org/standards/photo-metadata/)  
- 📄 [IPTC Photo Metadata Mapping Guidelines](https://iptc.org/standards/photo-metadata/mapping-guidelines/)  
- 📄 [IPTC Photo Metadata User Guide](https://iptc.org/std/photometadata/documentation/UserGuide/)  
- 📄 [IPTC Core & Extension](https://iptc.org/standards/photo-metadata/iptc-core/)  
- 📄 [ExifTool Tag Names (XMP/EXIF/IPTC)](https://exiftool.org/TagNames/XMP.html)  
- 📄 [IPTC ninjs – JSON schéma pro zprávy/fotky](https://iptc.org/standards/ninjs/)

## Core Functionality

### 1. JSON-Based Metadata Extraction & User Field Population

When an image is uploaded, the system:
1. **Extracts** all IPTC/EXIF/XMP metadata using ExifTool
2. **Stores** complete raw metadata in `file_metadata` JSON column  
3. **Populates** blank user-editable fields from extracted metadata
4. **Preserves** all original metadata for display/analysis

**Extraction Process:**
```ruby
# 1. Extract raw metadata with namespace preservation
raw_metadata = extract_raw_metadata_with_exiftool(file_path) 
# => {
#   "XMP-dc:Creator" => ["John Doe", "Jane Smith"],
#   "XMP-photoshop:Headline" => "Breaking News Photo", 
#   "XMP-iptcCore:CreditLine" => "Reuters",
#   "Make" => "Canon", "Model" => "EOS R5",
#   "DateTimeOriginal" => "2024:03:15 14:30:00",
#   "GPSLatitude" => 50.0755, ...
# }

# 2. Store ALL metadata in JSON (never loses data)
file.update!(file_metadata: raw_metadata)

# 3. Auto-populate blank user fields (preserves existing values)
populate_user_fields_from_metadata(file) if file.should_extract_metadata?
```

**User Field Population Logic:**
```ruby
def populate_user_fields_from_metadata(file)
  # Only fill blank fields - never overwrite user data
  if file.author.blank?
    creators = extract_creators_from_json(file.file_metadata)
    file.author = creators.join(", ") if creators.any?
  end
  
  if file.description.blank?
    headline = file.file_metadata&.dig("XMP-photoshop:Headline") ||
               file.file_metadata&.dig("Headline")
    file.description = headline if headline.present?
  end
  
  if file.attribution_copyright.blank?
    copyright = file.file_metadata&.dig("XMP-photoshop:Copyright") ||
               file.file_metadata&.dig("XMP-dc:rights")
    file.attribution_copyright = copyright if copyright.present?
  end
  
  # Populate essential columns for business logic
  file.capture_date = parse_capture_date_from_json(file.file_metadata) if file.capture_date.blank?
  file.gps_latitude = file.file_metadata&.dig("GPSLatitude") if file.gps_latitude.blank?
  file.gps_longitude = file.file_metadata&.dig("GPSLongitude") if file.gps_longitude.blank?
end
```

**Metadata Display (Read-Only Access):**
All IPTC metadata accessible via getters that query the JSON:
```ruby
def headline
  file_metadata&.dig("XMP-photoshop:Headline") || file_metadata&.dig("Headline")
end

def creator_list
  creators = file_metadata&.dig("XMP-dc:Creator") || 
            file_metadata&.dig("By-line") || file_metadata&.dig("Artist")
  Array(creators).reject(&:blank?)
end

def credit_line_from_metadata
  file_metadata&.dig("XMP-iptcCore:CreditLine") ||
  file_metadata&.dig("Credit") || file_metadata&.dig("XMP-photoshop:Credit")  
end
```

**Implementation Notes:**
- Uses ExifTool with `-G1 -struct -n -charset iptc=utf8` flags
- Preserves namespace information (`XMP-dc:Creator` vs `IPTC:By-line`)
- **UTF-8 charset handling**: Prevents mojibake in Czech/Slovak content
- All metadata always available in JSON, regardless of schema changes
- User fields remain fully editable and indexed for search

📋 **[Complete implementation details →](image_metadata/json_based_mapping.md)**

### 2. IPTC Charset Encoding

**Problem**: JPEG files with Czech/Slovak characters in IPTC metadata often contain UTF-8 data, but ExifTool reads them as Latin-1 by default → creates mojibake (`ÄŒesk` instead of `Česk`).

**Root Cause**: ExifTool ignores IPTC CodedCharacterSet (1:90) indicator and defaults to Latin-1 encoding, even when files contain UTF-8 data marked with `\x1b%G` UTF-8 indicator.

**Solution**: Force UTF-8 charset in ExifTool configuration:

```ruby
# config/initializers/folio_image_metadata.rb
config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"]
```

**Results**:
- ✅ **Before**: `"ÄŒTK / Å imÃ¡nek VÃ­t"` (mojibake)
- ✅ **After**: `"ČTK / Šimánek Vít"` (correct UTF-8)

**Fallback for legacy files**:
```ruby
# When UTF-8 fails, try additional charsets
config.folio_image_metadata_iptc_charset_candidates = %w[utf8 cp1250 iso-8859-2 cp1252]
```

**Verification**:
```bash
# Test raw ExifTool output
exiftool -G1 -struct -n -charset iptc=utf8 -j file.jpg
```

Fields like `Caption-Abstract`, `IPTC:By-line` should contain proper Czech characters.

📋 **[Detailed charset encoding guide →](image_metadata/charset_encoding.md)**

### 3. Configuration Options

Applications can configure metadata extraction behavior through initializers:

```ruby  
# config/initializers/folio_image_metadata.rb

Rails.application.config.tap do |config|
  # Enable/disable metadata extraction globally
  config.folio_image_metadata_extraction_enabled = true # default: true
  
  # ExifTool command options for metadata extraction
  # Force UTF-8 for IPTC to prevent Czech/Slovak mojibake
  config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"]
  
  # When UTF-8 fails, try these charset candidates for legacy files  
  config.folio_image_metadata_iptc_charset_candidates = %w[utf8 cp1250 iso-8859-2 cp1252]
  
  # User field auto-population using IptcFieldMapper
  config.folio_image_metadata_populate_user_fields = {
    headline: :headline,                        # Uses IptcFieldMapper with fallbacks
    author: :creator,                           # Uses IptcFieldMapper (array → joined string)  
    description: :description,                  # Uses IptcFieldMapper with fallbacks
    attribution_copyright: :copyright_notice,   # Uses IptcFieldMapper
    attribution_source: :credit_line,          # Uses IptcFieldMapper with derived source
    capture_date: :capture_date,                # Uses IptcFieldMapper with timezone parsing
    gps_latitude: :gps_latitude,                # Uses IptcFieldMapper with decimal conversion
    gps_longitude: :gps_longitude,              # Uses IptcFieldMapper with decimal conversion
    # keywords: merged into tag_list automatically (no config needed)
  }
  
  # Skip auto-population for specific fields (user controls these manually)
  config.folio_image_metadata_skip_population_fields = []
  
  # Copy metadata to image placements
  config.folio_image_metadata_copy_to_placements = true # default: true
  
  # Tags integration - merge extracted keywords into tag_list
  config.folio_image_metadata_merge_keywords_to_tags = true # default: true
  
  # Language priority for multi-language XMP fields (dc:description, dc:rights, etc.)
  config.folio_image_metadata_locale_priority = [:cs, :en, "x-default"] 
end
```

**Key Changes in JSON-Based Approach**:
- ✅ **Simplified Config**: No complex field mappings, just population rules
- ✅ **All Data Preserved**: Raw metadata always stored in JSON
- ✅ **User Control**: Clear separation between auto-population and metadata display
- ✅ **Charset Handling**: Built-in UTF-8 support with fallbacks

### 4. Conditional Processing

Metadata extraction only occurs when:
- `exiftool` binary is available on the system
- Global extraction is enabled via configuration
- Target database fields are blank (no overwriting)
- File is an image type (JPEG, PNG, TIFF, etc.)

### 5. Image Placement Metadata

When creating new image placements, metadata can be automatically copied from the source image:

```ruby
class Folio::FilePlacement::Image
  # Automatically inherits metadata from file when created
  before_validation :copy_metadata_from_file, on: :create
  
  private
  
  def copy_metadata_from_file
    return unless Rails.application.config.folio_image_metadata_copy_to_placements
    return unless file.is_a?(Folio::File::Image)
    
    self.alt ||= file.alt
    self.title ||= file.title
    self.caption ||= file.description
  end
end
```

### 6. Custom Mapping in Applications

Applications can define custom mapping logic:

```ruby
# app/models/concerns/custom_metadata_extraction.rb
module CustomMetadataExtraction
  extend ActiveSupport::Concern
  
  included do
    after_commit :extract_custom_metadata, on: :create
  end
  
  private
  
  def extract_custom_metadata
    return unless file_metadata.present?
    
    # Custom logic for specific fields
    if file_metadata["ColorSpace"] == "sRGB"
      update_column(:additional_data, { color_profile: "web-safe" })
    end
    
    # GPS coordinates to location
    if file_metadata["GPSLatitude"] && file_metadata["GPSLongitude"]
      update_columns(
        geo_lat: parse_gps(file_metadata["GPSLatitude"]),
        geo_lng: parse_gps(file_metadata["GPSLongitude"])
      )
    end
  end
end
```

## User Experience

### Console Interface

1. **Upload View:**
   - Shows metadata extraction status
   - Displays extracted fields before saving
   - Allows manual override of extracted values

2. **Bulk Operations:**
   - "Extract metadata" action for existing files
   - Progress indicator for batch processing
   - Report of extracted/skipped files

3. **File Detail View:**
   - "Metadata" tab showing all extracted EXIF/IPTC data
   - Indicators for auto-filled vs manually edited fields
   - "Re-extract" button (with confirmation for non-blank fields)

## Implementation Phases

### Phase 1: Core Extraction
- [ ] Basic field mapping (author, description, alt)
- [ ] Blank field protection
- [ ] Configuration framework

### Phase 2: Advanced Features
- [ ] Custom mapping support
- [ ] Placement metadata copying
- [ ] Console UI enhancements

### Phase 3: Optimization
- [ ] Background job processing for large files
- [ ] Caching of metadata extraction rules
- [ ] Batch extraction tools

## Technical Considerations

### Performance
- Metadata extraction runs in `after_commit` callback
- Consider moving to background job for large uploads
- Cache mapping configuration per request

### Data Integrity
- Always preserve user-entered data
- Log metadata extraction actions
- Provide rollback mechanism for bulk operations

### Testing
```ruby
# test/models/folio/file/image_metadata_extraction_test.rb
class ImageMetadataExtractionTest < ActiveSupport::TestCase
  test "extracts author from Artist field" do
    image = create_image_with_metadata("Artist" => "John Doe")
    assert_equal "John Doe", image.author
  end
  
  test "preserves existing author value" do
    image = create(:folio_file_image, author: "Jane Smith")
    image.extract_metadata!
    assert_equal "Jane Smith", image.author
  end
  
  test "respects configuration to disable extraction" do
    with_config(folio_image_metadata_extraction_enabled: false) do
      image = create_image_with_metadata("Artist" => "John Doe")
      assert_nil image.author
    end
  end
end
```

## Potential Enhancements

### Future Improvements

1. **AI-Powered Enhancements**
   - Auto-generate alt text from image content
   - Suggest keywords based on visual analysis
   - Face detection for automatic author tagging

2. **Workflow Integration**
   - Approval workflow for extracted metadata
   - Diff view for metadata changes
   - Bulk editing with metadata templates

3. **Advanced Mapping**
   - Regular expression support in mappings
   - Conditional mappings based on file source
   - Field transformation functions (lowercase, titleize, etc.)

4. **SEO Optimization**
   - Automatic meta tag generation from metadata
   - Structured data (schema.org) integration
   - Image sitemap enrichment

5. **Developer Experience** 📖 [→ Detailed Documentation](image_metadata/image_metadata_developer_experience.md)
   - Rails generators for custom extractors
   - Metadata extraction hooks/events system
   - Testing tools and console commands

## Database Schema Strategy

**Core Principle**: Metadata stays in JSON, only essential business-critical fields get dedicated columns.

### Current Schema (Preserved + Headline)
```ruby
# Existing folio_files schema + headline field
create_table "folio_files" do |t|
  t.string "file_uid"
  t.string "file_name" 
  t.string "type"
  t.text "thumbnail_sizes", default: "--- {}\n"
  t.datetime "created_at", precision: nil, null: false
  t.datetime "updated_at", precision: nil, null: false
  t.integer "file_width"
  t.integer "file_height"
  t.bigint "file_size"
  t.json "additional_data"
  t.json "file_metadata"           # ← RAW IPTC/EXIF/XMP DATA STORED HERE
  t.string "hash_id"
  t.string "headline"              # ← USER EDITABLE (Titulek)
  t.string "author"                # ← USER EDITABLE (Autor)
  t.text "description"             # ← USER EDITABLE (Popis) 
  t.integer "file_placements_size"
  t.string "file_name_for_search"
  t.boolean "sensitive_content", default: false
  t.string "file_mime_type"
  t.string "default_gravity"
  t.integer "file_track_duration"
  t.string "aasm_state"
  t.json "remote_services_data", default: {}
  t.integer "preview_track_duration_in_seconds"
  t.string "alt"                   # ← USER EDITABLE (Alt, images only)
  t.bigint "site_id", null: false
  t.string "attribution_source"    # ← USER EDITABLE (Zdroj)
  t.string "attribution_source_url" # ← USER EDITABLE (Zdroj URL)
  t.string "attribution_copyright"  # ← USER EDITABLE (Copyright)
  t.string "attribution_licence"    # ← USER EDITABLE (Licence)
end
```

### New Columns (Minimal Addition)
Only add columns that are **essential for business logic**, not available in original schema:

```ruby
# db/migrate/add_essential_metadata_fields_to_folio_files.rb
class AddEssentialMetadataFieldsToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    # User-editable field for headline/title
    add_column :folio_files, :headline, :string
    
    # Technical metadata - needed for display/sorting
    add_column :folio_files, :capture_date, :datetime
    add_index :folio_files, :capture_date
    
    # GPS coordinates - needed for geographic queries  
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6 
    add_index :folio_files, [:gps_latitude, :gps_longitude]
    
    # Keywords merged into existing tag_list system (no new column needed)
  end
end
```

**Total: 4 new columns** vs original 30+ column approach.

### Database Columns vs JSON Display

**Database Columns** (User-Editable):
```ruby
# These are actual database columns - fully editable in forms
file.headline              # "Major Event" (string column) 
file.author                # "John Doe" (string column)
file.description           # "Breaking news" (text column)
file.alt                   # "Photo description" (string column)
file.attribution_source    # "Reuters" (string column)
file.attribution_source_url # "https://..." (string column)
file.attribution_copyright  # "© 2024" (string column)
file.attribution_licence    # "CC BY" (string column)

# Auto-filled business columns (indexed/queryable)
file.capture_date          # 2024-03-15 14:30:00 (datetime)
file.gps_latitude         # 50.0755 (decimal)
file.gps_longitude        # 14.4378 (decimal)
```

**JSON Display Getters** (Read-Only):
```ruby
# Simple getters for UI display (NOT used for auto-population)
def creator
  file_metadata&.dig("XMP-dc:Creator") || []
end

def credit_line  
  file_metadata&.dig("XMP-iptcCore:CreditLine") || file_metadata&.dig("Credit")
end

def camera_make
  file_metadata&.dig("Make") 
end

def camera_model
  file_metadata&.dig("Model")
end

def copyright_notice
  file_metadata&.dig("XMP-photoshop:Copyright")
end
```

### Data Flow & Automatic Field Population

**1. Metadata Extraction Process**:
```ruby
# After file upload, ExifTool extracts raw metadata
raw_metadata = extract_raw_metadata_with_exiftool(file_path)
# => { "XMP-dc:Creator" => ["John Doe"], "XMP-photoshop:Headline" => "News Photo", ... }

# Store ALL raw metadata in file_metadata JSON
file.update(file_metadata: raw_metadata)

# ✅ Use IptcFieldMapper to map with fallbacks and special processing
mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
# => { headline: "News Photo", creator: ["John Doe"], capture_date: Time.parse(...), ... }

# Automatically populate BLANK user fields from mapped data
populate_user_fields_from_mapped_data(file, mapped_data)
```

**2. Auto-Population Logic** (Uses IptcFieldMapper with Fallbacks):
```ruby
def populate_user_fields_from_mapped_data(file, mapped_data)
  # Only populate blank fields (never overwrite user data)
  
  # ✅ Editable database columns (uses IptcFieldMapper results)
  file.headline = mapped_data[:headline] if file.headline.blank? && mapped_data[:headline].present?
  file.author = Array(mapped_data[:creator]).join(", ") if file.author.blank? && mapped_data[:creator].present?
  file.description = mapped_data[:description] || mapped_data[:headline] if file.description.blank?
  file.attribution_copyright = mapped_data[:copyright_notice] if file.attribution_copyright.blank?
  file.attribution_source = mapped_data[:credit_line] || mapped_data[:source] if file.attribution_source.blank?
  
  # ✅ Essential business columns (indexed/queryable)
  file.capture_date = mapped_data[:capture_date] if file.capture_date.blank?
  file.gps_latitude = mapped_data[:gps_latitude] if file.gps_latitude.blank?
  file.gps_longitude = mapped_data[:gps_longitude] if file.gps_longitude.blank?
  
  # ✅ Merge keywords with existing tag_list system (no new column needed)
  if file.respond_to?(:tag_list) && mapped_data[:keywords].present?
    existing_tags = file.tag_list_array || []
    new_keywords = Array(mapped_data[:keywords])
    file.tag_list = (existing_tags + new_keywords).uniq
  end
  
  file.save if file.changed?
end
```

**3. Key Points**:

✅ **IptcFieldMapper** handles all complexity:
- **Fallback logic**: `XMP-photoshop:Headline` → `IPTC:Headline` → `Headline`
- **COMPLEX_FIELD_PROCESSORS**: Special handling for dates, GPS, arrays
- **Derived fields**: Source from credit_line if blank
- **Locale support**: Multi-language metadata
- **Provider detection**: Auto-detect Getty, Shutterstock, etc.

✅ **Auto-population respects existing logic**:
- All your fallback chains work exactly as before
- `capture_date` parsing with timezone handling
- `creator` array → joined string for `author` field
- `keywords` array → merged into existing `tag_list` system

✅ **Nothing is lost**:
```ruby
# These work exactly as they did before - using IptcFieldMapper
mapped = IptcFieldMapper.map_metadata(file.file_metadata)
mapped[:headline]        # Uses all defined fallbacks
mapped[:creator]         # Properly processed array
mapped[:capture_date]    # Parsed with timezone support
mapped[:gps_latitude]    # Decimal conversion
mapped[:keywords]        # Array merged into tag_list
```

**4. User vs Metadata Precedence**:
```ruby
# User-editable fields (what shows in form)
file.author                    # "John Doe, Jane Smith" (user editable)
file.description              # "User entered description" (user editable)
file.attribution_copyright    # "© 2024 Reuters" (user editable)

# Read-only metadata display (from JSON)
file.creator                  # ["John Doe", "Jane Smith"] (from JSON)  
file.headline                 # "Breaking News Photo" (from JSON)
file.copyright_notice         # "© 2024 Reuters" (from JSON)
```

**5. Benefits**:
- 🔒 **Data Safety**: Raw metadata preserved forever in JSON
- 🚀 **Performance**: User fields indexed/searchable, metadata display cached  
- 🎛️ **Flexibility**: Users can edit working copies, metadata stays pristine
- 📊 **Analytics**: All original IPTC data available for reporting

## Migration Path

For existing installations:

```ruby
# lib/tasks/folio_image_metadata.rake
namespace :folio do
  namespace :images do
    desc "Extract metadata for existing images"
    task extract_metadata: :environment do
      Folio::File::Image.find_each do |image|
        next if image.creator.present? && image.description.present?
        
        image.extract_metadata!
        print "."
      end
      puts "\nMetadata extraction complete!"
    end
    
    desc "Extract metadata with namespace support"
    task extract_metadata_iptc: :environment do
      require 'open3'
      
      Folio::File::Image.find_each do |image|
        next unless image.file.present?
        
        # Use ExifTool with namespace grouping
        stdout, stderr, status = Open3.capture3(
          "exiftool", "-j", "-G1", "-struct", "-n", image.file.path
        )
        
        if status.success?
          metadata = JSON.parse(stdout).first
          image.map_iptc_metadata(metadata)
          image.save if image.changed?
          print "."
        else
          puts "\nError processing #{image.file_name}: #{stderr}"
        end
      end
      puts "\nIPTC metadata extraction complete!"
    end
  end
end
```

## Configuration Reference

```yaml
# config/folio.yml
folio:
  image_metadata:
    enabled: true
    copy_to_placements: true
    mappings:
      author:
        - Artist
        - Creator
        - Copyright
      description:
        - Caption
        - Description
    skip_fields:
      - attribution_licence
    fallback_locale: en
```

---

*This specification is a living document and will be updated as the feature evolves.*

## 2025-08 Update: JSON-Based Metadata with User Field Auto-Population

**Core Architecture**:
- All raw IPTC/EXIF/XMP metadata stored in `file_metadata` JSON column
- User-editable fields remain as dedicated columns (`author`, `description`, `attribution_*`)  
- Metadata extraction populates blank user fields from JSON data (one-time)
- Advanced metadata displayed from JSON (read-only tables)

**Data Flow**:
1. **Extract** → Store raw metadata in JSON
2. **Populate** → Fill blank user fields from JSON (author ← creator, description ← headline)
3. **Display** → User fields editable, JSON metadata read-only
4. **Preserve** → User edits never lost, JSON metadata always available

**No Database Schema Explosion**: 4 new columns vs 30+ in original plan
**No Data Loss**: All IPTC data preserved in JSON forever
**User Control**: Clear separation between user fields and metadata display

### UI in File Modal

**Editable Fields** (Above-the-fold):
1. `headline` - User editable (Titulek) 
2. `description` - User editable (Popis)
3. `alt` - User editable (Alt, images only)
4. `author` - User editable (Autor)
5. `attribution_source` - User editable (Zdroj)
6. `attribution_source_url` - User editable (Zdroj URL)  
7. `attribution_copyright` - User editable (Copyright)
8. `attribution_licence` - User editable (Licence)
9. Default crop (Výchozí ořez, images only)

**Read-Only Metadata Display** (Collapsible "Advanced Metadata" section):
- **Descriptive Metadata Table**: 
  - Headline, Creator(s), Caption Writer, Credit Line, Source (from metadata)
  - Keywords, Intellectual Genre, Subject Codes, Event, Category
  - Persons Shown, Organizations Shown
- **Technical Metadata Table**:
  - Camera Make/Model, Lens Info, Capture Date, GPS Coordinates
  - Dimensions, File Size, Orientation, Color Profile
- **Rights Metadata Table**:
  - Copyright Notice, Copyright Marked, Usage Terms, Rights URL
- **Location Metadata Table**:
  - Location Created/Shown, City, State/Province, Country

**Action Row**: `[Save] [Extract metadata] [Re-extract metadata] [short localized extraction info]`

**Key Principles**:
- ✅ User fields are **never overwritten** by extraction
- ✅ Metadata fields are **display-only** (organized tables, not form inputs)  
- ✅ "Extract metadata" fills **only blank user fields** from extracted data
- ✅ Advanced metadata shows **all available IPTC/EXIF data** from JSON

### Keywords → tag_list
- After extraction, keywords from `XMP-dc:Subject` (via IptcFieldMapper) are merged into existing `tag_list` system
- No new `extracted_keywords` column needed - uses existing tag infrastructure  
- Existing tags preserved, duplicates removed, keywords only added if `tag_list` supported

### Translations
- UI strings are provided via `window.FolioConsole.translations` under `file/*` and `file/metadata/*` keys.

### Overrides
- If the host application injects its own file modal (e.g., economia-cms), its override is respected; Folio defaults apply otherwise.

---

## Implementation Summary (JSON-Based Approach)

### ✅ **What Changes**:
1. **Database**: Add only 4 essential columns (`headline`, `capture_date`, `gps_latitude`, `gps_longitude`)
2. **Storage**: All IPTC/EXIF/XMP metadata stored in existing `file_metadata` JSON column  
3. **UI**: Advanced metadata becomes read-only display tables (no form inputs)
4. **Population**: Auto-fill blank user fields from JSON metadata on upload
5. **Display**: JSON metadata getters provide rich metadata for display/analytics
6. **Keywords**: Merged into existing `tag_list` system (no new column needed)

### ✅ **What Stays Same**:
1. **User Fields**: `headline`, `author`, `description`, `alt`, `attribution_*` remain fully editable
2. **ExifTool Integration**: Same extraction process with UTF-8 charset fix
3. **Configuration**: Same configuration system, simplified options
4. **Field Mappings**: Same IPTC standard mappings, just JSON-based access
5. **Blank Protection**: Never overwrite user data

### ✅ **Benefits**:
- 🔒 **Data Safety**: Raw metadata never lost, always in JSON
- 🚀 **Performance**: Essential fields indexed, metadata cached
- 🎛️ **User Control**: Clear editable vs display-only separation
- 🏗️ **Schema Stability**: Minimal database changes (4 vs 30+ columns)
- 📊 **Analytics**: Full IPTC data available for reporting
- 🌍 **Internationalization**: UTF-8 charset handling built-in

### ✅ **Migration Strategy**:
1. **Phase 1**: Add 4 new columns, implement JSON getters
2. **Phase 2**: Update UI to show read-only metadata tables  
3. **Phase 3**: Implement user field auto-population
4. **Phase 4**: Add re-extraction capability

This approach provides all the benefits of IPTC standard compliance while maintaining a clean, maintainable codebase and excellent user experience.
