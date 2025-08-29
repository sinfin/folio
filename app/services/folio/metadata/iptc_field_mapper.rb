# frozen_string_literal: true

module Folio::Metadata
  class IptcFieldMapper
    # Encoding fix constants
    CZECH_CHARS_REGEX = /[ěščřžýáíéúůťďňóĚŠČŘŽÝÁÍÉÚŮŤĎŇÓ]/
    MOJIBAKE_PATTERNS_REGEX = /(Ã.|Â.|â..|√|≈|ƒ|�|Ä|Å¡|Å¾|Å¯|Å™|Äœ)/

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

      # Additional technical metadata with formatting
      focal_length: [
        "ExifIFD:FocalLength",
        "FocalLength"
      ],

      aperture: [
        "ExifIFD:FNumber",
        "Composite:Aperture",
        "FNumber"
      ],

      shutter_speed: [
        "ExifIFD:ExposureTime",
        "Composite:ShutterSpeed",
        "ExposureTime"
      ],

      iso_speed: [
        "ExifIFD:ISO",
        "ISO"
      ],

      flash: [
        "ExifIFD:Flash",
        "Flash"
      ],

      white_balance: [
        "ExifIFD:WhiteBalance",
        "WhiteBalance"
      ],

      exposure_mode: [
        "ExifIFD:ExposureMode",
        "ExposureMode"
      ],

      exposure_compensation: [
        "ExifIFD:ExposureCompensation",
        "ExposureCompensation"
      ],

      metering_mode: [
        "ExifIFD:MeteringMode",
        "MeteringMode"
      ],

      color_space: [
        "ExifIFD:ColorSpace",
        "ColorSpace"
      ],

      software: [
        "IFD0:Software",
        "Software"
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

      # Creator as joined string (better for UI display)
      creator: ->(value, metadata = {}) {
        case value
        when Array
          value.filter_map(&:to_s).reject(&:blank?).join(", ")
        when String
          value.to_s
        else
          ""
        end
      },

      description: ->(value, metadata = {}) {
        value.to_s
      },
      credit_line: ->(value, metadata = {}) {
        value.to_s
      },

      source: ->(value, metadata = {}) {
        # If source is not available, fallback to credit_line
        if value.blank?
          # Try to get credit_line from metadata
          credit_sources = ["XMP-iptcCore:CreditLine", "XMP-photoshop:Credit", "Credit", "IPTC:Credit"]
          credit_line = credit_sources.map { |field| metadata[field] }.find(&:present?)
          credit_line&.to_s || ""
        else
          value.to_s
        end
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
      },

      # Technical metadata with formatting
      focal_length: ->(value, metadata = {}) {
        return nil unless value
        "#{value.to_f.round}mm"
      },

      aperture: ->(value, metadata = {}) {
        return nil unless value
        "f/#{value.to_f}"
      },

      shutter_speed: ->(value, metadata = {}) {
        return nil unless value
        speed = value.to_f
        if speed < 1
          "1/#{(1 / speed).round}s"
        else
          "#{speed}s"
        end
      },

      iso_speed: ->(value, metadata = {}) {
        value.to_s
      },

      flash: ->(value, metadata = {}) {
        return nil unless value
        locale = metadata[:_locale] || I18n.locale || :en

        case value.to_i
        when 0
          I18n.t("folio.console.file.metadata.flash_values.not_used", locale: locale, default: "Not used")
        when 1, 9, 13, 15, 16, 24, 25, 29, 31
          I18n.t("folio.console.file.metadata.flash_values.used", locale: locale, default: "Used")
        else
          I18n.t("folio.console.file.metadata.flash_values.used_with_value",
                 value: value, locale: locale, default: "Used (#{value})")
        end
      },

      white_balance: ->(value, metadata = {}) {
        return nil unless value
        locale = metadata[:_locale] || I18n.locale || :en

        case value.to_i
        when 0
          I18n.t("folio.console.file.metadata.white_balance_values.auto", locale: locale, default: "Auto")
        when 1
          I18n.t("folio.console.file.metadata.white_balance_values.manual", locale: locale, default: "Manual")
        else
          value.to_s
        end
      },

      exposure_mode: ->(value, metadata = {}) {
        return nil unless value
        locale = metadata[:_locale] || I18n.locale || :en

        case value.to_i
        when 0
          I18n.t("folio.console.file.metadata.exposure_mode_values.auto", locale: locale, default: "Auto")
        when 1
          I18n.t("folio.console.file.metadata.exposure_mode_values.manual", locale: locale, default: "Manual")
        when 2
          I18n.t("folio.console.file.metadata.exposure_mode_values.aperture_priority", locale: locale, default: "Aperture priority")
        else
          value.to_s
        end
      },

      exposure_compensation: ->(value, metadata = {}) {
        return nil unless value
        comp = value.to_f
        return "0" if comp == 0
        "#{comp > 0 ? '+' : ''}#{comp.round(1)} EV"
      },

      metering_mode: ->(value, metadata = {}) {
        return nil unless value
        locale = metadata[:_locale] || I18n.locale || :en

        case value.to_i
        when 1
          I18n.t("folio.console.file.metadata.metering_mode_values.average", locale: locale, default: "Average")
        when 2
          I18n.t("folio.console.file.metadata.metering_mode_values.center_weighted", locale: locale, default: "Center-weighted")
        when 3
          I18n.t("folio.console.file.metadata.metering_mode_values.spot", locale: locale, default: "Spot")
        when 5
          I18n.t("folio.console.file.metadata.metering_mode_values.matrix", locale: locale, default: "Matrix")
        else
          value.to_s
        end
      },

      color_space: ->(value, metadata = {}) {
        return nil unless value
        locale = metadata[:_locale] || I18n.locale || :en

        case value.to_i
        when 1
          I18n.t("folio.console.file.metadata.color_space_values.srgb", locale: locale, default: "sRGB")
        when 65535
          I18n.t("folio.console.file.metadata.color_space_values.adobe_rgb", locale: locale, default: "Adobe RGB")
        else
          value.to_s
        end
      },

      software: ->(value, metadata = {}) {
        value.to_s
      },


    }.freeze

    class << self
      def map_metadata(raw_metadata, locale: nil)
        locale ||= I18n.locale || configured_locale_priority.first
        result = {}

        # Inject locale into metadata for processors
        enhanced_metadata = raw_metadata.dup
        enhanced_metadata[:_locale] = locale

        # Allow app-specific field mappings to override defaults
        field_mappings = effective_field_mappings

        field_mappings.each do |target_field, source_fields|
          value = extract_first_available_value(enhanced_metadata, source_fields, locale: locale, raw_metadata: raw_metadata)

          if value.present?
            # Apply special processing if defined (allow app overrides)
            processors = effective_field_processors
            if processor = processors[target_field]
              # Pass enhanced metadata (with locale) for processors
              value = processor.arity == 2 ? processor.call(value, enhanced_metadata) : processor.call(value)
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

      # Single method to get any field - used by models for delegation
      def get_field(raw_metadata, field_name, record = nil, locale: nil)
        return nil unless raw_metadata.present?

        # Special handling for GPS fields that prefer DB column values
        if [:gps_latitude, :gps_longitude].include?(field_name) && record
          column_value = record[field_name]
          return column_value if column_value.present?
        end

        mapped_data = map_metadata(raw_metadata, locale: locale)
        mapped_data[field_name]
      end

      # Allow applications to override field mappings
      def effective_field_mappings
        app_mappings = Rails.application.config.respond_to?(:folio_image_metadata_field_mappings) ?
                      Rails.application.config.folio_image_metadata_field_mappings : {}
        FIELD_MAPPINGS.merge(app_mappings || {})
      end

      # Allow applications to override field processors
      def effective_field_processors
        app_processors = Rails.application.config.respond_to?(:folio_image_metadata_field_processors) ?
                        Rails.application.config.folio_image_metadata_field_processors : {}
        COMPLEX_FIELD_PROCESSORS.merge(app_processors || {})
      end

      # Configurable locale priority
      def configured_locale_priority
        Rails.application.config.folio_image_metadata_locale_priority || [:en, "x-default"]
      end

      private
        def extract_first_available_value(metadata, source_fields, locale: :en, raw_metadata: {})
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
              return extract_lang_alt(value, locale, raw_metadata: raw_metadata)
            end

            # Fix encoding issues in text values before returning
            return unmojibake(value, raw_metadata)
          end
          nil
        end

        # Handle XMP Lang Alt structures with configurable priority
        def extract_lang_alt(lang_alt, locale = :en, raw_metadata: {})
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
            if lang_alt[loc_str].present?
              value = lang_alt[loc_str]
              return unmojibake(value, raw_metadata)
            end

            # Try with region (e.g., "cs-CZ")
            regional_key = "#{loc_str}-#{loc_str.upcase}"
            if lang_alt[regional_key].present?
              value = lang_alt[regional_key]
              return unmojibake(value, raw_metadata)
            end

            # Try any variant starting with locale (e.g., "en-US", "en-GB")
            lang_alt.each do |key, value|
              if key.to_s.start_with?("#{loc_str}-") && value.present?
                return unmojibake(value, raw_metadata)
              end
            end
          end

          # Fallback to x-default
          if lang_alt["x-default"].present?
            value = lang_alt["x-default"]
            return unmojibake(value, raw_metadata)
          end

          # Last resort: first available value
          first_value = lang_alt.values.first
          unmojibake(first_value, raw_metadata)
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

        def unmojibake(str, metadata = {})
          return str if str.nil?

          # Handle Arrays (e.g., XMP-dc:Creator)
          if str.is_a?(Array)
            return str.map { |item| unmojibake(item, metadata) }
          end

          # Only process Strings - return other types as-is
          return str unless str.is_a?(String)
          return str if str.empty?

          # Check IPTC-IIM CodedCharacterSet (1:90) to respect standard
          coded_charset = metadata["CodedCharacterSet"] || metadata["IPTC:CodedCharacterSet"]

          # IPTC-IIM standard:
          # - když 1:90 = "UTF8" (ESC % G), dekóduj všechna IPTC pole jako UTF-8
          # - když 1:90 chybí, default je ISO-8859-1

          case coded_charset&.to_s&.upcase
          when "UTF8", "%G"
            # Data should be UTF-8 (%G is ESC % G sequence for UTF-8)
            # Only apply mojibake fix if text actually needs it
            if needs_encoding_fix?(str)
              return fix_utf8_mojibake(str)
            else
              return str  # Text is already correct UTF-8
            end
          when nil, "", "ISO-8859-1"
            # Default IPTC encoding should be ISO-8859-1, but check if already UTF-8
            # If text looks like it needs mojibake fix, apply it; otherwise try ISO-8859-1 conversion
            if needs_encoding_fix?(str)
              return fix_utf8_mojibake(str)
            else
              begin
                # Try ISO-8859-1 to UTF-8 conversion
                converted = str.dup.force_encoding("ISO-8859-1").encode("UTF-8", invalid: :replace, undef: :replace)
                # Only use if it doesn't make things worse
                if score_cs(converted) >= score_cs(str)
                  return converted
                else
                  return str
                end
              rescue
                return str
              end
            end
          else
            # Other declared charset, try to convert
            begin
              ruby_encoding = charset_to_ruby_name(coded_charset)
              return str.dup.force_encoding(ruby_encoding).encode("UTF-8", invalid: :replace, undef: :replace)
            rescue
              # Fallback to unmojibake logic
            end
          end

          # Fallback: apply full unmojibake logic for problematic cases
          fix_utf8_mojibake(str)
end

        def fix_utf8_mojibake(str)
          # 1) zkusi ICU (only if it detects non-UTF-8 encoding)
          begin
            require "charlock_holmes"
            if det = CharlockHolmes::EncodingDetector.detect(str)
              # Skip if already UTF-8 - likely false positive for mojibake
              if det[:encoding] && det[:encoding] != "UTF-8" && det[:confidence] > 80
                begin
                  converted = CharlockHolmes::Converter.convert(str, det[:encoding], "UTF-8")
                  # Only use if it actually improves the score
                  if score_cs(converted) > score_cs(str)
                    return converted
                  end
                rescue
                  # Continue to fallback methods
                end
              end
            end
          rescue LoadError
            # charlock_holmes not available, continue to fallback
          end

          # 2) kandidáti + reverse-bytes (double-mojibake)
          csets = %w[Windows-1250 Windows-1252 ISO-8859-2 ISO-8859-1 MacRoman]
          candidates = []

          csets.each do |cs|
            candidates << str.dup.force_encoding(cs).encode("UTF-8", invalid: :replace, undef: :replace) rescue nil
            bytes = str.encode(cs, "UTF-8", invalid: :replace, undef: :replace) rescue nil
            if bytes
              candidates << bytes.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace) rescue nil
            end
          end

          candidates.compact.max_by { |t| score_cs(t) } || str
        end

        def needs_encoding_fix?(str)
          return false if str.nil?

          # Handle Arrays
          if str.is_a?(Array)
            return str.any? { |item| needs_encoding_fix?(item) }
          end

          # Only check Strings
          return false unless str.is_a?(String)
          return false if str.empty?

          # Check if text contains common mojibake patterns indicating encoding issues
          str.match?(MOJIBAKE_PATTERNS_REGEX)
end

        def charset_to_ruby_name(charset)
          case charset.to_s.upcase
          when "UTF8", "UTF-8" then "UTF-8"
          when "ISO-8859-1", "LATIN1" then "ISO-8859-1"
          when "ISO-8859-2", "LATIN2" then "ISO-8859-2"
          when "WINDOWS-1250", "CP1250" then "Windows-1250"
          when "WINDOWS-1252", "CP1252" then "Windows-1252"
          when "MACROMAN" then "MacRoman"
          else charset
          end
        end

        def score_cs(text)
          text.scan(CZECH_CHARS_REGEX).size * 3 - text.scan(MOJIBAKE_PATTERNS_REGEX).size * 6 - [text.count("?") - 2, 0].max
        end
    end
  end
end
