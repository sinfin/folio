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

### 1. Automatic Field Mapping

When an image is uploaded, the system automatically extracts and saves metadata to database columns following **IPTC Photo Metadata Standard** with proper namespace precedence. **Existing data is never overwritten** - extraction only fills blank fields.

📋 **[Migration Guide with Backward Compatibility →](image_metadata/iptc_migration_with_aliases.md)**

**Metadata Precedence (recommended by IPTC):**
1. **XMP** (preferred, richest namespace support)
2. **IPTC-IIM** (legacy compatibility)  
3. **EXIF** (technical data: timestamp, GPS, camera settings)

**Standard Field Mappings:**
```ruby
{
  # Core descriptive fields
  headline: ["XMP-photoshop:Headline", "Headline"],
  description: ["XMP-dc:description", "Caption-Abstract", "ImageDescription"],
  creator: ["XMP-dc:creator", "By-line", "Artist"],  # Store as JSONB array
  caption_writer: ["XMP-photoshop:CaptionWriter"],
  credit_line: ["XMP-iptcCore:CreditLine", "XMP-photoshop:Credit", "Credit"],
  source: ["XMP-iptcCore:Source", "XMP-photoshop:Source", "Source"],
  
  # Rights management  
  copyright_notice: ["XMP-photoshop:Copyright", "XMP-dc:rights"],
  copyright_marked: ["XMP-xmpRights:Marked"],  # Boolean
  usage_terms: ["XMP-xmpRights:UsageTerms"],
  rights_usage_info: ["XMP-xmpRights:WebStatement"],  # URL
  
  # Classification (JSONB arrays)
  keywords: ["XMP-dc:subject"],  # Store as JSONB array
  intellectual_genre: ["XMP-iptcCore:IntellectualGenre"],
  subject_codes: ["XMP-iptcCore:SubjectCode"],  # JSONB array
  scene_codes: ["XMP-iptcCore:Scene"],  # JSONB array
  event: ["XMP-iptcCore:Event"],  # Single string
  
  # Legacy fields (deprecated)
  category: ["XMP-photoshop:Category", "Category"],
  urgency: ["XMP-photoshop:Urgency", "Urgency"],
  
  # People and objects (JSONB arrays)
  persons_shown: ["XMP-iptcExt:PersonInImage"],
  persons_shown_details: ["XMP-iptcExt:PersonInImageWDetails"],
  organizations_shown: ["XMP-iptcExt:OrganisationInImageName"],
  
  # Location data
  location_created: ["XMP-iptcExt:LocationCreated"],  # JSONB array of structs
  location_shown: ["XMP-iptcExt:LocationShown"],  # JSONB array of structs
  sublocation: ["XMP-iptcCore:Location"],  # Neighborhood/venue
  city: ["XMP-photoshop:City", "City"],
  state_province: ["XMP-photoshop:State", "Province-State"],
  country: ["XMP-iptcCore:CountryName", "Country-PrimaryLocationName", "Country"],
  country_code: ["XMP-iptcCore:CountryCode", "Country-PrimaryLocationCode"],  # 2 chars
  
  # Technical metadata from EXIF
  camera_make: ["Make"],
  camera_model: ["Model"], 
  lens_info: ["LensModel", "LensInfo"],
  capture_date: ["DateTimeOriginal", "XMP-photoshop:DateCreated", "XMP-xmp:CreateDate", "CreateDate"],
  gps_latitude: ["GPSLatitude"],
  gps_longitude: ["GPSLongitude"],
  orientation: ["Orientation"]
}
```

**Implementation notes:**
- Uses ExifTool with `-G1 -struct -n` flags for namespace-qualified extraction
- Mappings processed with XMP precedence over IPTC-IIM over EXIF
- Only updates fields if they are blank (preserves user edits)
- Runs after file processing completes

📋 **[Complete Ruby mapping implementation →](image_metadata/iptc_metadata_mapping.md)**

### 2. Configuration Options

Applications can configure metadata extraction behavior through initializers:

```ruby
# config/initializers/folio.rb

Rails.application.config.tap do |config|
  # Enable/disable metadata extraction globally
  config.folio_image_metadata_extraction_enabled = true # default: true
  
  # Use IPTC-compliant field mappings (recommended)
  config.folio_image_metadata_use_iptc_standard = true # default: true
  
  # Custom field mappings (extends IPTC standard)
  config.folio_image_metadata_custom_mappings = {
    # Override IPTC mapping for specific fields
    headline: ["XMP-custom:CompanyTitle", "XMP-photoshop:Headline", "Headline"],
    
    # Add completely custom fields
    project_name: ["XMP-custom:ProjectName", "XMP-iptcExt:Event"],
    internal_reference: ["XMP-custom:InternalRef"]
  }
  
  # Fields to skip during extraction
  config.folio_image_metadata_skip_fields = [:urgency, :categories]
  
  # Industry standard validation (optional)
  config.folio_image_metadata_require_agency_fields = false # default: false
  config.folio_image_metadata_required_fields = [
    :creator, :credit_line, :copyright_notice, :source
  ] # IPTC recommended fields for professional use
  
  # Extract metadata to placements
  config.folio_image_metadata_copy_to_placements = true # default: true
  
  # ExifTool command options
  config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n"] # default
  
  # Language priority for Lang Alt fields (dc:description, dc:rights, etc.)
  config.folio_image_metadata_locale_priority = [:cs, :en, "x-default"] # Czech first, then English
  # Default: [:en, "x-default"]
end
```

### 3. Conditional Processing

Metadata extraction only occurs when:
- `exiftool` binary is available on the system
- Global extraction is enabled via configuration
- Target database fields are blank (no overwriting)
- File is an image type (JPEG, PNG, TIFF, etc.)

### 4. Image Placement Metadata

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

### 5. Custom Mapping in Applications

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

## Database Schema Changes

The feature requires additional columns in the `folio_files` table to store IPTC-compliant metadata:

```ruby
# db/migrate/add_iptc_metadata_fields_to_folio_files.rb
class AddIptcMetadataFieldsToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    # Core descriptive fields
    add_column :folio_files, :headline, :string
    add_column :folio_files, :creator, :jsonb, default: []  # Array of creators
    add_column :folio_files, :caption_writer, :string
    add_column :folio_files, :credit_line, :string
    add_column :folio_files, :source, :string
    
    # Rights management
    add_column :folio_files, :copyright_notice, :text
    add_column :folio_files, :copyright_marked, :boolean, default: false
    add_column :folio_files, :usage_terms, :text
    add_column :folio_files, :rights_usage_info, :string  # URL
    
    # Classification (JSONB arrays for multi-value fields)
    add_column :folio_files, :keywords, :jsonb, default: []
    add_column :folio_files, :intellectual_genre, :string
    add_column :folio_files, :subject_codes, :jsonb, default: []
    add_column :folio_files, :scene_codes, :jsonb, default: []
    add_column :folio_files, :event, :string  # Single event string
    
    # Legacy fields (for backwards compatibility)
    add_column :folio_files, :category, :string
    add_column :folio_files, :urgency, :integer
    
    # People and objects (JSONB arrays)
    add_column :folio_files, :persons_shown, :jsonb, default: []
    add_column :folio_files, :persons_shown_details, :jsonb, default: []
    add_column :folio_files, :organizations_shown, :jsonb, default: []
    
    # Location data
    add_column :folio_files, :location_created, :jsonb, default: []  # Array of structs
    add_column :folio_files, :location_shown, :jsonb, default: []    # Array of structs
    add_column :folio_files, :sublocation, :string  # Neighborhood/venue
    add_column :folio_files, :city, :string
    add_column :folio_files, :state_province, :string
    add_column :folio_files, :country, :string
    add_column :folio_files, :country_code, :string, limit: 2  # ISO 3166-1 alpha-2
    
    # Technical metadata
    add_column :folio_files, :camera_make, :string
    add_column :folio_files, :camera_model, :string
    add_column :folio_files, :lens_info, :string
    add_column :folio_files, :capture_date, :datetime
    add_column :folio_files, :capture_date_offset, :string  # Store original timezone
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :orientation, :integer
    
    # Indexes for common searches (GIN for JSONB arrays)
    add_index :folio_files, :creator, using: :gin
    add_index :folio_files, :keywords, using: :gin
    add_index :folio_files, :subject_codes, using: :gin
    add_index :folio_files, :persons_shown, using: :gin
    add_index :folio_files, :source
    add_index :folio_files, :country_code
    add_index :folio_files, :capture_date
    add_index :folio_files, [:gps_latitude, :gps_longitude]
  end
end
```

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
