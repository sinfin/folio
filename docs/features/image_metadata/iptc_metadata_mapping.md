# IPTC Metadata Mapping - Ruby Implementation

## Ready-to-Use Ruby Hash Mapping

Complete mapping following IPTC Photo Metadata Standard with XMP/IPTC-IIM/EXIF precedence.

### Core Mapping Hash

```ruby
# app/services/folio/metadata/iptc_field_mapper.rb
module Folio::Metadata
  class IptcFieldMapper
    
    # Complete mapping with namespace precedence
    FIELD_MAPPINGS = {
      # Core descriptive fields (IPTC Core)
      headline: [
        "XMP-photoshop:Headline",
        "Headline"  # IIM fallback
      ],
      
      description: [
        "XMP-dc:description",  # Lang Alt primary source
        "Caption-Abstract",    # IIM fallback
        "ImageDescription"     # EXIF fallback
      ],
      
      creator: [
        "XMP-dc:creator",  # Array of names
        "By-line",         # IIM fallback
        "Artist"           # EXIF fallback
      ],
      
      caption_writer: [
        "XMP-photoshop:CaptionWriter"
      ],
      
      credit_line: [
        "XMP-iptcCore:CreditLine",
        "XMP-photoshop:Credit",
        "Credit"  # IIM fallback
      ],
      
      source: [
        "XMP-iptcCore:Source",
        "XMP-photoshop:Source",
        "Source"  # IIM fallback
      ],
      
      # Rights management (XMP Rights & IPTC)
      copyright_notice: [
        "XMP-photoshop:Copyright",
        "XMP-dc:rights"  # Lang Alt
      ],
      
      copyright_marked: [
        "XMP-xmpRights:Marked"  # Boolean
      ],
      
      usage_terms: [
        "XMP-xmpRights:UsageTerms"  # Lang Alt
      ],
      
      rights_usage_info: [
        "XMP-xmpRights:WebStatement"  # URL
      ],
      
      # Classification
      keywords: [
        "XMP-dc:subject"  # Array/bag, store as JSONB array
      ],
      
      intellectual_genre: [
        "XMP-iptcCore:IntellectualGenre"
      ],
      
      subject_codes: [
        "XMP-iptcCore:SubjectCode"  # Array
      ],
      
      scene_codes: [
        "XMP-iptcCore:Scene"  # Array
      ],
      
      event: [
        "XMP-iptcCore:Event",  # IPTC Core (preferred)
        "XMP-iptcExt:Event"    # IPTC Extension (fallback)
      ],
      
      # Legacy fields (deprecated but may be needed for older content)
      urgency: [
        "XMP-photoshop:Urgency",
        "Urgency"  # IIM fallback
      ],
      
      category: [
        "XMP-photoshop:Category",
        "Category"  # IIM fallback
      ],
      
      # People and objects (IPTC Extension)
      persons_shown: [
        "XMP-iptcExt:PersonInImage"  # Array
      ],
      
      persons_shown_details: [
        "XMP-iptcExt:PersonInImageWDetails"  # Array of structs
      ],
      
      organizations_shown: [
        "XMP-iptcExt:OrganisationInImageName"  # Array
      ],
      
      # Location data (IPTC Extension + Photoshop)
      location_created: [
        "XMP-iptcExt:LocationCreated"  # Array of structs
      ],
      
      location_shown: [
        "XMP-iptcExt:LocationShown"  # Array of structs
      ],
      
      sublocation: [
        "XMP-iptcCore:Location"  # Sub-location (neighborhood, venue)
      ],
      
      city: [
        "XMP-photoshop:City",
        "City"  # IIM fallback
      ],
      
      state_province: [
        "XMP-photoshop:State",
        "Province-State"  # IIM fallback
      ],
      
      country: [
        "XMP-iptcCore:CountryName",
        "Country-PrimaryLocationName",  # IIM fallback
        "Country"
      ],
      
      country_code: [
        "XMP-iptcCore:CountryCode",  # ISO 3166-1 alpha-2 (2 chars)
        "Country-PrimaryLocationCode"  # IIM fallback
      ],
      
      # Technical metadata (EXIF)
      camera_make: [
        "Make"
      ],
      
      camera_model: [
        "Model"
      ],
      
      lens_info: [
        "LensModel",
        "LensInfo"
      ],
      
      capture_date: [
        "DateTimeOriginal",      # EXIF original capture time (preferred)
        "XMP-photoshop:DateCreated",  # XMP fallback
        "XMP-xmp:CreateDate",     # XMP fallback
        "CreateDate"              # EXIF fallback
      ],
      
      gps_latitude: [
        "GPSLatitude"  # With -n flag, returns signed decimal
      ],
      
      gps_longitude: [
        "GPSLongitude"  # With -n flag, returns signed decimal
      ],
      
      orientation: [
        "Orientation"
      ]
    }.freeze
    
    # Special handling for complex fields
    COMPLEX_FIELD_PROCESSORS = {
      # Keep arrays as JSONB, don't concatenate to string
      keywords: ->(value) {
        normalize_array(value)
      },
      
      subject_codes: ->(value) {
        normalize_array(value)
      },
      
      scene_codes: ->(value) {
        normalize_array(value)
      },
      
      persons_shown: ->(value) {
        normalize_array(value)
      },
      
      persons_shown_details: ->(value) {
        # Keep structured data as-is for PersonInImageWDetails
        case value
        when Array then value
        when Hash then [value]
        else []
        end
      },
      
      organizations_shown: ->(value) {
        normalize_array(value)
      },
      
      # Structured location arrays - keep as JSONB
      location_created: ->(value) {
        case value
        when Array then value  # Array of location structs
        when Hash then [value]  # Single location struct
        else []
        end
      },
      
      location_shown: ->(value) {
        case value
        when Array then value  # Array of location structs
        when Hash then [value]  # Single location struct
        else []
        end
      },
      
      # Boolean field
      copyright_marked: ->(value) {
        case value
        when true, "true", "True", 1 then true
        when false, "false", "False", 0 then false
        else nil
        end
      },
      
      # With -n flag, ExifTool returns signed decimal directly
      gps_latitude: ->(value, metadata = {}) {
        parse_gps_decimal(value)
      },
      
      gps_longitude: ->(value, metadata = {}) {
        parse_gps_decimal(value)
      },
      
      # Proper datetime parsing with timezone support
      capture_date: ->(value) {
        result = parse_capture_date(value)
        # Extract just the time for capture_date field
        result.is_a?(Hash) ? result[:time] : result
      },
      
      # Creator can be array or single value
      creator: ->(value) {
        case value
        when Array then value  # Keep as array for JSONB storage
        when String then [value]
        else []
        end
      }
    }.freeze
    
    def self.map_metadata(raw_metadata, locale: nil)
      locale ||= configured_locale_priority.first
      result = {}
      
      FIELD_MAPPINGS.each do |target_field, source_fields|
        value = extract_first_available_value(raw_metadata, source_fields, locale: locale)
        
        if value.present?
          # Apply special processing if defined
          if processor = COMPLEX_FIELD_PROCESSORS[target_field]
            # Pass full metadata for fields that need additional context (like GPS)
            value = processor.arity == 2 ? processor.call(value, raw_metadata) : processor.call(value)
          end
          
          result[target_field] = value
        end
      end
      
      result
    end
    
    # Configurable locale priority
    def self.configured_locale_priority
      Rails.application.config.folio_image_metadata_locale_priority || [:en, "x-default"]
    end
    
    private
    
    def self.extract_first_available_value(metadata, source_fields, locale: :en)
      source_fields.each do |field|
        value = metadata[field]
        next if value.blank?
        
        # Handle Lang Alt structures (XMP dc:description, dc:rights, etc.)
        if value.is_a?(Hash) && (value.key?("lang") || value.keys.any? { |k| k.to_s.include?("-") })
          return extract_lang_alt(value, locale)
        end
        
        return value
      end
      nil
    end
    
    # Handle XMP Lang Alt structures with configurable priority
    def self.extract_lang_alt(lang_alt, locale = :en)
      return lang_alt unless lang_alt.is_a?(Hash)
      
      # Get configured locale priority
      locale_priority = configured_locale_priority
      
      # If specific locale requested, put it first
      if locale && !locale_priority.include?(locale.to_s)
        locale_priority = [locale.to_s] + locale_priority
      end
      
      # Try each locale in priority order
      locale_priority.each do |loc|
        loc_str = loc.to_s
        
        # Try exact match
        return lang_alt[loc_str] if lang_alt[loc_str].present?
        
        # Try with region (e.g., "cs-CZ")
        return lang_alt["#{loc_str}-#{loc_str.upcase}"] if lang_alt["#{loc_str}-#{loc_str.upcase}"].present?
        
        # Try any variant starting with locale (e.g., "en-US", "en-GB")
        lang_alt.each do |key, value|
          return value if key.to_s.start_with?("#{loc_str}-") && value.present?
        end
      end
      
      # Fallback to x-default
      return lang_alt["x-default"] if lang_alt["x-default"].present?
      
      # Last resort: first available value
      lang_alt.values.first
    end
    
    # Normalize various inputs to clean arrays
    def self.normalize_array(value)
      case value
      when Array
        value.compact.reject(&:blank?)
      when String
        # Don't split - preserve original strings in arrays
        [value]
      else
        []
      end
    end
    
    # Parse GPS with -n flag (already signed decimal)
    def self.parse_gps_decimal(value)
      return nil if value.blank?
      
      case value
      when Numeric
        value.to_f
      when String
        # With -n flag, ExifTool returns signed decimal directly
        # e.g., -33.7490 for South, -118.2437 for West
        value.to_f
      else
        nil
      end
    end
    
    # Parse capture date with timezone awareness
    def self.parse_capture_date(value)
      return nil if value.blank?
      
      case value
      when String
        # Parse and preserve timezone if present
        # ExifTool formats: "2024:03:15 14:30:00+02:00" or "2024-03-15T14:30:00+02:00"
        begin
          parsed_time = Time.parse(value)
          
          # Extract and store offset for separate field if needed
          if value =~ /([+-]\d{2}:\d{2}|Z)$/
            offset = $1
            # Store in a hash to return both time and offset
            { time: parsed_time, offset: offset }
          else
            { time: parsed_time, offset: nil }
          end
        rescue
          nil
        end
      when Time, DateTime
        { time: value, offset: value.formatted_offset }
      else
        nil
      end
    end
  end
end
```

## Usage Examples

### Basic Usage

```ruby
# Extract metadata using ExifTool
require 'open3'

stdout, stderr, status = Open3.capture3(
  "exiftool", "-j", "-G1", "-struct", "-n", image_path
)

if status.success?
  raw_metadata = JSON.parse(stdout).first
  mapped_fields = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
  
  # Update image with mapped fields
  image.update!(mapped_fields.compact_blank)
end
```

### Integration with Folio::File::Image

```ruby
# app/models/folio/file/image.rb
class Folio::File::Image < Folio::File
  
  def extract_iptc_metadata!
    return unless file.present?
    
    raw_metadata = extract_raw_metadata_with_namespaces
    return if raw_metadata.blank?
    
    mapped_fields = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
    
    # Only update blank fields (preserve user edits)
    update_fields = {}
    mapped_fields.each do |field, value|
      if self.send(field).blank? && value.present?
        update_fields[field] = value
      end
    end
    
    update!(update_fields) if update_fields.any?
  end
  
  private
  
  def extract_raw_metadata_with_namespaces
    return {} unless file&.path.present?
    
    stdout, stderr, status = Open3.capture3(
      "exiftool", "-j", "-G1", "-struct", "-n", file.path
    )
    
    if status.success?
      JSON.parse(stdout).first || {}
    else
      Rails.logger.error "ExifTool error: #{stderr}"
      {}
    end
  end
end
```

### Custom Field Mapping

```ruby
# config/initializers/folio_metadata.rb
Rails.application.config.after_initialize do
  # Extend or override default mappings
  custom_mappings = {
    headline: [
      "XMP-custom:CompanyHeadline",  # Custom field first
      *Folio::Metadata::IptcFieldMapper::FIELD_MAPPINGS[:headline]
    ],
    
    # Add new field
    project_name: [
      "XMP-custom:ProjectName",
      "XMP-iptcExt:Event"
    ]
  }
  
  Folio::Metadata::IptcFieldMapper::FIELD_MAPPINGS.merge!(custom_mappings)
end
```

## Testing the Mapping

```ruby
# test/services/folio/metadata/iptc_field_mapper_test.rb
require 'test_helper'

class Folio::Metadata::IptcFieldMapperTest < ActiveSupport::TestCase
  test "maps XMP fields with precedence" do
    metadata = {
      "XMP-photoshop:Headline" => "XMP Title",
      "Headline" => "IPTC Title",
      "Title" => "EXIF Title"
    }
    
    result = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)
    assert_equal "XMP Title", result[:headline]
  end
  
  test "processes complex keywords field" do
    metadata = {
      "XMP-dc:subject" => ["nature", "landscape", "photography"]
    }
    
    result = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)
    assert_equal "nature, landscape, photography", result[:keywords]
  end
  
  test "parses GPS coordinates" do
    metadata = {
      "GPSLatitude" => "50.0755° N",
      "GPSLongitude" => "14.4378° E"
    }
    
    result = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)
    assert_equal 50.0755, result[:gps_latitude]
    assert_equal 14.4378, result[:gps_longitude]
  end
end
```

## Command Line Testing

```bash
# Test the mapper with real images
rails runner "
  image_path = ARGV[0]
  stdout, _, status = Open3.capture3('exiftool', '-j', '-G1', '-struct', '-n', image_path)
  
  if status.success?
    raw = JSON.parse(stdout).first
    mapped = Folio::Metadata::IptcFieldMapper.map_metadata(raw)
    
    puts 'Raw metadata fields:'
    raw.keys.sort.each { |k| puts \"  #{k}: #{raw[k]}\" }
    
    puts \"\nMapped fields:\"
    mapped.each { |k, v| puts \"  #{k}: #{v}\" }
  else
    puts 'Error extracting metadata'
  end
" path/to/image.jpg
```

---

*This mapping follows IPTC Photo Metadata Standard v1.3 and ExifTool tag naming conventions.*
