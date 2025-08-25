# frozen_string_literal: true

module Folio::Metadata
  class IptcFieldMapper
    # Complete mapping with namespace precedence
    FIELD_MAPPINGS = {
      # Core descriptive fields (IPTC Core)
      headline: [
        "XMP-photoshop:Headline",
        "IPTC:Headline",  # IIM with group prefix
        "Headline"        # IIM fallback
      ],

      description: [
        "XMP-dc:Description",  # Lang Alt primary source (uppercase)
        "XMP-dc:description",  # Lang Alt primary source (lowercase)
        "Caption-Abstract",    # IIM fallback
        "ImageDescription"     # EXIF fallback
      ],

      creator: [
        "XMP-dc:Creator",  # Array of names (uppercase)
        "XMP-dc:creator",  # Array of names (lowercase)
        "By-line",         # IIM fallback
        "Artist"           # EXIF fallback
      ],

      caption_writer: [
        "XMP-photoshop:CaptionWriter"
      ],

      credit_line: [
        "XMP-iptcCore:CreditLine",
        "XMP-photoshop:Credit",
        "Credit",  # IIM fallback
        "IPTC:Credit"  # IIM fallback with group prefix
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

      # Non-standard but widely used by agencies (PLUS namespace)
      # Store licensor/provider page URL for attribution
      attribution_source_url: [
        "XMP-plus:LicensorURL",
        "XMP-xmpRights:WebStatement"  # Fallback when LicensorURL missing
      ],

      # Classification
      keywords: [
        "XMP-dc:Subject",  # Array/bag, store as JSONB array (uppercase)
        "XMP-dc:subject",  # Array/bag, store as JSONB array (lowercase)
        "IPTC:Keywords",   # IIM fallback (may be comma-separated String)
        "Keywords"         # IIM fallback without group prefix
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
        "ExifIFD:DateTimeOriginal",      # EXIF original capture time (preferred)
        "XMP-photoshop:DateCreated",  # XMP fallback
        "XMP-xmp:CreateDate",     # XMP fallback
        "ExifIFD:CreateDate",            # EXIF fallback
        "DateTimeOriginal",              # Fallback without prefix
        "CreateDate"                     # Fallback without prefix
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
      headline: ->(value, metadata = {}) {
        case value
        when Array
          value.compact.map(&:to_s).reject(&:blank?).join(", ")
        else
          value.to_s
        end
      },
      # Keep arrays as JSONB; for String fallbacks (IPTC:Keywords), split on commas/semicolons
      keywords: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?)
        when String
          value.split(/[;,]/).map { |s| s.to_s.strip }.reject(&:blank?)
        else
          []
        end
      },

      subject_codes: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?)
        when String
          [value.to_s].compact.reject(&:blank?)
        else
          []
        end
      },

      scene_codes: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?)
        when String
          [value.to_s].compact.reject(&:blank?)
        else
          []
        end
      },

      persons_shown: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?)
        when String
          [value.to_s].compact.reject(&:blank?)
        else
          []
        end
      },

      persons_shown_details: ->(value) {
        # Keep structured data as-is for PersonInImageWDetails
        case value
        when Array then value
        when Hash then [value]
        else []
        end
      },

      organizations_shown: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?)
        when String
          [value.to_s].compact.reject(&:blank?)
        else
          []
        end
      },

      # Country code must be ISO 3166-1 alpha-2 (2 chars max)
      country_code: ->(value) {
        return nil if value.blank?
        code = value.to_s.strip.upcase
        # Only take first 2 characters to ensure DB constraint compliance
        code.length > 2 ? code[0..1] : code
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
      creator: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?)
        when String
          [value.to_s].compact.reject(&:blank?)
        else
          []
        end
      },

      description: ->(value, metadata = {}) {
        value.to_s
      },
      credit_line: ->(value, metadata = {}) {
        value.to_s
      },
      source: ->(value, metadata = {}) {
        value.to_s
      },
      copyright_notice: ->(value, metadata = {}) {
        value.to_s
      },

      # Additional text fields
      caption_writer: ->(value, metadata = {}) {
        value.to_s
      },
      usage_terms: ->(value, metadata = {}) {
        value.to_s
      },
      intellectual_genre: ->(value, metadata = {}) {
        value.to_s
      },
      event: ->(value, metadata = {}) {
        value.to_s
      },
      category: ->(value, metadata = {}) {
        value.to_s
      },
      sublocation: ->(value, metadata = {}) {
        value.to_s
      },
      city: ->(value, metadata = {}) {
        value.to_s
      },
      state_province: ->(value, metadata = {}) {
        value.to_s
      },
      country: ->(value, metadata = {}) {
        value.to_s
      },
      camera_make: ->(value, metadata = {}) {
        value.to_s
      },
      camera_model: ->(value, metadata = {}) {
        value.to_s
      },
      lens_info: ->(value, metadata = {}) {
        value.to_s
      },

      # Legacy fields
      alt: ->(value, metadata = {}) {
        value.to_s
      },
      author: ->(value, metadata = {}) {
        value.to_s
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
              # Pass full metadata for fields that need additional context (like GPS or encoding repair)
              value = processor.arity == 2 ? processor.call(value, raw_metadata) : processor.call(value)
            end

            result[target_field] = value
          end
        end

        # Derive provider/source name from credit_line if source is blank (common in Getty/Shutterstock)
        if result[:source].blank? && result[:credit_line].present?
          # If credit_line contains slash-delimited provider, take the last segment as provider name
          credit = result[:credit_line].to_s
          derived = credit.split("/").last.to_s.strip
          result[:source] = derived.presence || credit
        end

        # Heuristic provider detection if still blank: scan common fields for known providers
        if result[:source].blank?
          provider_list = (Rails.application.config.folio_image_metadata_known_providers || [])
          haystack_values = [
            raw_metadata["IPTC:CopyrightNotice"],
            raw_metadata["XMP-dc:Rights"],
            raw_metadata["IFD0:Software"],
            raw_metadata["IPTC:OriginatingProgram"],
            raw_metadata["Photoshop:WriterName"],
            raw_metadata["Photoshop:ReaderName"]
          ].compact.map { |v| v.is_a?(Array) ? v.join(" ") : v.to_s }.join(' \n ')
          unless haystack_values.blank?
            provider_list.each do |prov|
              name = prov[:name]
              patterns = Array(prov[:patterns])
              if patterns.any? { |rx| haystack_values =~ rx }
                result[:source] = name
                break
              end
            end
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
            # If not found and the field is an unqualified IIM tag (no namespace),
            # try with common group prefix used by ExifTool when -G1 is enabled
            if value.blank? && !field.to_s.include?(":") && field.to_s =~ /[A-Za-z]/
              value = metadata["IPTC:#{field}"]
            end
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
            # ExifTool formats: "2024:03:15 14:30:00+02:00", "2024-03-15T14:30:00+02:00", or "2022:06:19 20:24:45"
            begin
              # Convert EXIF colon format to standard format for parsing
              normalized_value = value.gsub(/^(\d{4}):(\d{2}):(\d{2})/, '\1-\2-\3')

              parsed_time = Time.parse(normalized_value)

              # Extract and store offset for separate field if needed
              if value =~ /([+-]\d{2}:\d{2}|Z)$/
                offset = $1
                # Store in a hash to return both time and offset
                { time: parsed_time, offset: offset }
              else
                { time: parsed_time, offset: nil }
              end
            rescue => e
              Rails.logger.warn("Failed to parse capture date '#{value}': #{e.message}") if defined?(Rails)
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
