# frozen_string_literal: true

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
        "XMP-dc:Description",  # Lang Alt primary source
        "Caption-Abstract",    # IIM fallback
        "ImageDescription"     # EXIF fallback
      ],
      
      creator: [
        "XMP-dc:Creator",  # Array of names
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
        "XMP-dc:Rights"  # Lang Alt
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
        "XMP-dc:Subject"  # Array/bag, store as JSONB array
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
      ],
      
      # Legacy field mappings for backward compatibility
      author: [
        "XMP-dc:Creator",
        "By-line",
        "Artist"
      ],
      
      alt: [
        "XMP-photoshop:Headline",
        "Headline"
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
    
    class << self
      def map_metadata(raw_metadata, locale: nil)
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
      def configured_locale_priority
        Rails.application.config.folio_image_metadata_locale_priority || [:en, "x-default"]
      end
      
      private
      
      def extract_first_available_value(metadata, source_fields, locale: :en)
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
      def extract_lang_alt(lang_alt, locale = :en)
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
      def normalize_array(value)
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
      def parse_gps_decimal(value)
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
      def parse_capture_date(value)
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
end
