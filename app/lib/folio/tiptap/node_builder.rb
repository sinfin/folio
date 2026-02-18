# frozen_string_literal: true

class Folio::Tiptap::NodeBuilder
  def initialize(klass:, structure:, tiptap_config: nil)
    @klass = klass
    @structure = convert_structure_to_hashes(structure)
    @tiptap_config = get_tiptap_config(tiptap_config)
    @embed_keys = []
  end

  def build!
    build_structure!
    setup_html_sanitization_config!
    handle_config!
  end

  private
    def build_structure!
      @structure.each do |key, attr_config|
        if key == :type
          fail ArgumentError, "Cannot use reserved key `type` in tiptap_node definition"
        end

        case attr_config[:type]
        when :relation
          setup_structure_for_relation(key:, attr_config:)
        when :url_json
          setup_structure_for_url_json(key:)
        when :folio_attachment
          setup_structure_for_folio_attachment(key:, attr_config:)
        when :collection
          setup_structure_for_collection(key:, attr_config:)
        when :string,
             :text
          setup_structure_default(key:)
        when :rich_text
          setup_structure_for_rich_text(key:)
        when :integer
          setup_structure_for_integer(key:)
        when :embed
          setup_structure_for_embed(key:)
        else
          fail ArgumentError, "Unsupported type #{attr_config[:type]} in tiptap_node definition"
        end
      end

      @klass.class_variable_set(:@@structure, @structure)

      @klass.define_singleton_method :structure do
        class_variable_get(:@@structure)
      end
    end

    def setup_structure_for_relation(key:, attr_config:)
      if attr_config[:has_many]
        setup_structure_for_has_many(key:, class_name: attr_config[:class_name])
      else
        setup_structure_for_belongs_to(key:, class_name: attr_config[:class_name])
      end
    end

    def setup_structure_for_integer(key:)
      @klass.attribute key, type: :integer

      @klass.define_method "#{key}=" do |value|
        transformed_value = if value.nil?
          nil
        elsif value.is_a?(String) || value.is_a?(Numeric)
          value.to_i
        else
          fail ArgumentError, "Expected a String or Number for #{key}, got #{value.class.name}"
        end

        super(transformed_value)
      end
    end

    def setup_structure_default(key:)
      @klass.attribute key, type: :text
    end

    def setup_structure_for_collection(key:, attr_config:)
      if attr_config[:collection].nil?
        fail ArgumentError, "Expected :collection in attr_config for #{key}, got nil"
      end

      collection_types = attr_config[:collection].map { |item| item.class }.uniq

      if collection_types.all? { |type| type == TrueClass || type == FalseClass }
        @klass.attribute key, type: :boolean

        @klass.define_method "#{key}=" do |value|
          transformed_value = if value.nil?
            nil
          elsif value == true || value == false
            value
          elsif value.is_a?(String)
            case value
            when "true", "1" then true
            when "false", "0", "" then false
            else
              nil
            end
          else
            nil
          end

          super(transformed_value)
        end
      elsif collection_types.all? { |type| type == Integer }
        @klass.attribute key, type: :integer

        @klass.define_method "#{key}=" do |value|
          transformed_value = if value.nil?
            nil
          elsif value.is_a?(String) || value.is_a?(Numeric)
            value.to_i
          else
            nil
          end

          super(transformed_value)
        end
      else
        @klass.attribute key, type: :text
      end
    end

    def setup_structure_for_rich_text(key:)
      @klass.attribute key, type: :json
      # TODO validate rich_text JSON structure

      @klass.define_method "#{key}=" do |value|
        transformed_value = if value.nil?
          nil
        elsif value.is_a?(String)
          (JSON.parse(value) rescue {}) || {}
        elsif value.is_a?(Hash)
          value.stringify_keys
        else
          fail ArgumentError, "Expected a String or Hash for #{key}, got #{value.class.name}"
        end

        super(transformed_value)
      end
    end

    def setup_structure_for_url_json(key:)
      @klass.attribute key, type: :json

      @klass.define_method "#{key}=" do |value|
        if value.nil?
          return super(nil)
        end

        transformed_value = if value.is_a?(String)
          (JSON.parse(value) rescue {}) || {}
        elsif value.is_a?(Hash)
          value.stringify_keys
        else
          fail ArgumentError, "Expected a String or Hash for #{key}, got #{value.class.name}"
        end

        whitelisted = transformed_value.slice(*::Folio::Tiptap::ALLOWED_URL_JSON_KEYS).transform_values do |v|
          v.is_a?(String) ? v.strip.presence : nil
        end.compact

        # Sanitize href values to prevent dangerous URLs
        if whitelisted["href"].present?
          # Use Rails' sanitizer to check if href is safe
          test_link = "<a href=\"#{whitelisted["href"]}\">test</a>"
          sanitized_link = ActionController::Base.helpers.sanitize(test_link)

          # If href was stripped, it's unsafe
          if sanitized_link == "<a>test</a>"
            Rails.logger.warn "Removed unsafe href from tiptap node url_json: #{whitelisted["href"]}" if defined?(Rails.logger)
            whitelisted.delete("href")
          else
            # Extract href from sanitized result
            if match = sanitized_link.match(/href="([^"]*)"/)
              whitelisted["href"] = match[1]
            end
          end
        end

        super(whitelisted)
      end
    end

    def setup_structure_for_embed(key:)
      @klass.attribute key, type: :json

      @klass.define_method "#{key}=" do |value|
        super(Folio::Embed.normalize_value(value))
      end

      # Track embed keys for later sanitization config setup
      @embed_keys << key
    end

    def setup_structure_for_folio_attachment(key:, attr_config:)
      attr_config[:attachment_key]
      class_name = attr_config[:file_type]
      file_klass = class_name.constantize

      if attr_config[:has_many]
        # Store data in XXX_placements_attributes as array of hashes with file_id, title, alt, description and folio_embed_data
        #
        # Example:
        #   image_placements_attributes: [
        #     { "file_id" => 1, "title" => "Custom title", "alt" => "Custom alt" },
        #     { "file_id" => 2, "alt" => "Custom alt" },
        #     { "file_id" => 3 },
        #   ]
        @klass.attribute "#{key.to_s.singularize}_placements_attributes", type: :json, array: true, default: []

        # Override setter to enforce structure and whitelist keys
        @klass.define_method "#{key.to_s.singularize}_placements_attributes=" do |attributes|
          ary = []

          if attributes.present?
            if attributes.is_a?(Hash)
              ary = attributes.values
            elsif attributes.is_a?(Array)
              ary = attributes
            else
              fail ArgumentError, "Expected attributes to be a Hash or Array, got #{attributes.class.name}"
            end
          end

          whitelisted = []

          ary.each do |raw_value|
            value = raw_value.with_indifferent_access

            if value[:file_id] && value[:_destroy] != "1"
              whitelisted << {
                "file_id" => value[:file_id].to_i,
                "title" => value[:title].presence,
                "alt" => value[:alt].presence,
                "description" => value[:description].presence,
                "folio_embed_data" => Folio::Embed.normalize_value(value[:folio_embed_data])
              }.compact
            end
          end

          super(whitelisted)
        end

        # Placeholder placements getter for compatibility with existing code
        @klass.define_method "#{key.to_s.singularize}_placements" do
          send("#{key.to_s.singularize}_placements_attributes").map do |attrs|
            Folio::FilePlacement::Tiptap.new(file_id: attrs["file_id"],
                                             title: attrs["title"],
                                             alt: attrs["alt"],
                                             description: attrs["description"],
                                             folio_embed_data: attrs["folio_embed_data"])
          end
        end

        # Files getter for compatibility with existing code
        @klass.define_method(key) do
          ids = send("#{key.to_s.singularize}_placements_attributes").map { |attrs| attrs["file_id"] }

          if ids.present?
            file_klass.where(id: ids).to_a
          else
            []
          end
        end

        # Files setter for compatibility with existing code
        @klass.define_method("#{key}=") do |value|
          if value.is_a?(Array) && value.all? { |v| v.is_a?(file_klass) }
            attributes_ary = value.map do |file|
              {
                "file_id" => file.id,
                "title" => file.title.presence,
                "alt" => file.alt.presence,
                "description" => file.description.presence,
              }.compact
            end

            send("#{key.to_s.singularize}_placements_attributes=", attributes_ary)
          else
            fail ArgumentError, "Expected an Array of #{file_klass.name} for #{key}, got #{value}"
          end
        end

        # Files ids setter for compatibility with existing code
        @klass.define_method("#{key.to_s.singularize}_ids=") do |raw_ary|
          raw_ary ||= []

          unless raw_ary.is_a?(Array)
            fail ArgumentError, "Expected an Array for #{key.to_s.singularize}_ids, got #{raw_ary.class.name}"
          end

          ary = []

          raw_ary.each do |raw_value|
            if raw_value.present?
              if raw_value.is_a?(String)
                ary << raw_value.to_i
              elsif raw_value.is_a?(Integer)
                ary << raw_value
              else
                fail ArgumentError, "Expected a String or Integer for #{key.to_s.singularize}_ids, got #{raw_value.class.name}"
              end
            end
          end

          files = file_klass.where(id: ary)

          send("#{key.to_s.singularize}=", files)
        end
      else
        # Store data in XXX_placement_attributes as a hash with file_id, title, alt, description and folio_embed_data
        #
        # Example:
        #   cover_placements_attributes: {
        #     "file_id" => 1, "title" => "Custom title", "alt" => "Custom alt"
        #   }
        @klass.attribute "#{key}_placement_attributes", type: :json

        # Override setter to enforce structure and whitelist keys
        @klass.define_method "#{key}_placement_attributes=" do |raw_value|
          value = raw_value.with_indifferent_access

          if value[:file_id] && value[:_destroy] != "1"
            super({
              "file_id" => value[:file_id].to_i,
              "title" => value[:title].presence,
              "alt" => value[:alt].presence,
              "description" => value[:description].presence,
              "folio_embed_data" => Folio::Embed.normalize_value(value[:folio_embed_data])
            }.compact)
          else
            super(nil)
          end
        end

        # File getter for compatibility with existing code
        @klass.define_method(key) do
          attrs = send("#{key}_placement_attributes")

          if attrs && attrs["file_id"]
            file_klass.find_by(id: attrs["file_id"])
          end
        end

        # File setter for compatibility with existing code
        @klass.define_method("#{key}=") do |file|
          if file.nil?
            send("#{key}_placement_attributes=", nil)
          elsif file.is_a?(file_klass)
            send("#{key}_placement_attributes=", {
              "file_id" => file.id,
              "title" => file.title.presence,
              "alt" => file.alt.presence,
              "description" => file.description.presence,
            }.compact)
          else
            fail ArgumentError, "Expected a #{file_klass.name} for #{key}, got #{value.class.name}"
          end
        end

        # Placeholder methods for compatibility with Folio::Console::Files::PickerComponent
        @klass.define_method "#{key}_placement" do
          attrs = send("#{key}_placement_attributes")

          if attrs && attrs["file_id"].present?
            Folio::FilePlacement::Tiptap.new(file_id: attrs["file_id"],
                                             title: attrs["title"],
                                             alt: attrs["alt"],
                                             description: attrs["description"],
                                             folio_embed_data: attrs["folio_embed_data"])
          end
        end

        @klass.define_method "build_#{key}_placement" do
          Folio::FilePlacement::Tiptap.new
        end

        @klass.define_method("#{key}_id=") do |raw_value|
          value = if raw_value.present?
            if raw_value.is_a?(String)
              raw_value.to_i
            elsif raw_value.is_a?(Integer)
              raw_value
            else
              fail ArgumentError, "Expected a String or Integer for #{key}_id, got #{raw_value.class.name}"
            end
          else
            nil
          end

          file = file_klass.find_by(id: value)
          send("#{key}=", file)
        end
      end
    end

    def setup_structure_for_belongs_to(key:, class_name:)
      @klass.attribute "#{key}_id", type: :integer
      belongs_to_klass = class_name.constantize

      @klass.define_method(key) do
        belongs_to_klass.find_by(id: send("#{key}_id"))
      end

      # always cast ids to integers when setting them
      @klass.define_method("#{key}_id=") do |raw_value|
        value = if raw_value.present?
          if raw_value.is_a?(String)
            raw_value.to_i
          elsif raw_value.is_a?(Integer)
            raw_value
          else
            fail ArgumentError, "Expected a String or Integer for #{key}_id, got #{raw_value.class.name}"
          end
        else
          nil
        end

        super(value)
      end

      @klass.define_method("#{key}=") do |value|
        if value.nil?
          send("#{key}_id=", nil)
        elsif value.is_a?(belongs_to_klass)
          send("#{key}_id=", value.id)
        else
          fail ArgumentError, "Expected a #{belongs_to_klass.name} for #{key}, got #{value.class.name}"
        end
      end
    end

    def setup_structure_for_has_many(key:, class_name:)
      @klass.attribute "#{key.to_s.singularize}_ids", type: :integer, array: true, default: []
      has_many_klass = class_name.constantize

      @klass.define_method(key) do
        ids = send("#{key.to_s.singularize}_ids")

        if ids.present?
          has_many_klass.where(id: ids).to_a
        else
          []
        end
      end

      # always cast ids to integers when setting them
      @klass.define_method("#{key.to_s.singularize}_ids=") do |raw_ary|
        raw_ary ||= []

        unless raw_ary.is_a?(Array)
          fail ArgumentError, "Expected an Array for #{key.to_s.singularize}_ids, got #{raw_ary.class.name}"
        end

        ary = []

        raw_ary.each do |raw_value|
          if raw_value.present?
            if raw_value.is_a?(String)
              ary << raw_value.to_i
            elsif raw_value.is_a?(Integer)
              ary << raw_value
            else
              fail ArgumentError, "Expected a String or Integer for #{key.to_s.singularize}_ids, got #{raw_value.class.name}"
            end
          end
        end

        super(ary)
      end

      @klass.define_method("#{key}=") do |value|
        if value.is_a?(Array) && value.all? { |v| v.is_a?(has_many_klass) }
          send("#{key.to_s.singularize}_ids=", value.map(&:id))
        else
          fail ArgumentError, "Expected an Array of #{has_many_klass.name} for #{key}, got #{value}"
        end
      end
    end

    def convert_structure_to_hashes(structure)
      result = {}

      structure.each do |key, value|
        if value.is_a?(Hash)
          if value[:type].is_a?(Symbol)
            result[key] = value
          elsif value[:class_name].present?
            result[key] = { type: :relation, class_name: value[:class_name], has_many: value[:has_many] || false }
          else
            fail ArgumentError, "Expected :type or :class_name in hash for #{key}, got #{value.inspect}"
          end
        elsif value.is_a?(Array)
          result[key] = { type: :collection, collection: value }
        elsif value.is_a?(Symbol)
          case value
          when :image
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              file_type: "Folio::File::Image",
              has_many: false
            }
          when :document
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              file_type: "Folio::File::Document",
              has_many: false
            }
          when :audio_cover
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              file_type: "Folio::File::Audio",
              has_many: false
            }
          when :video_cover
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              file_type: "Folio::File::Video",
              has_many: false
            }
          when :images
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placements".to_sym,
              file_type: "Folio::File::Image",
              has_many: true
            }
          when :documents
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placements".to_sym,
              file_type: "Folio::File::Document",
              has_many: true
            }
          when :embed
            result[key] = { type: :embed }
          else
            result[key] = { type: value }
          end
        else
          fail ArgumentError, "Expected a Hash, Array or a Symbol for #{key}, got #{value.class.name}"
        end
      end

      result
    end

    # Structure of allowed keys and their value types in tiptap_config hash, hashes cannot include keys not listed here.
    # For hash values, each key specifies types: [] and optionally optional: true
    TIPTAP_CONFIG_HASH_STRUCTURE = {
      icon: { types: [String] },
      toolbar_slot: { types: [String] },
      group: { types: [String] },
      autoclick_cover: { types: [TrueClass, FalseClass] },
      paste: {
        pattern: { types: [Regexp] },
        lambda: { types: [Proc] },
        error_message_lambda: { types: [Proc], optional: true },
      },
    }

    def get_tiptap_config(tiptap_config_hash_or_nil)
      if tiptap_config_hash_or_nil.is_a?(Hash)
        tiptap_config_hash_or_nil.each do |key, value|
          if value.nil?
            fail ArgumentError, "Expected value for `#{key}` in tiptap_config to be present, got nil"
          end

          if TIPTAP_CONFIG_HASH_STRUCTURE[key].nil?
            fail ArgumentError, "Unknown key `#{key}` in tiptap_config. Allowed keys are: #{TIPTAP_CONFIG_HASH_STRUCTURE.keys.join(', ')}"
          end

          config_spec = TIPTAP_CONFIG_HASH_STRUCTURE[key]

          if config_spec.key?(:types)
            # Simple value type check (like icon, toolbar_slot, group, autoclick_cover)
            unless config_spec[:types].any? { |type| value.is_a?(type) }
              raise ArgumentError, "Expected value for `#{key}` in tiptap_config to be of type #{config_spec[:types].join(' or ')}, got #{value.class.name}"
            end
          else
            # Hash config (like paste)
            # Check that all keys in value are in whitelist and match their types
            value.each do |k, v|
              unless config_spec.key?(k)
                raise ArgumentError, "Unknown key `#{k}` in `#{key}` config. Allowed keys are: #{config_spec.keys.join(', ')}"
              end

              key_config = config_spec[k]
              unless key_config[:types].any? { |type| v.is_a?(type) }
                raise ArgumentError, "Expected `#{key}.#{k}` in tiptap_config to be of type #{key_config[:types].join(' or ')}, got #{v.class.name}"
              end
            end

            # Check required keys (keys without optional: true)
            required_keys = config_spec.select do |k, key_config|
              !key_config[:optional]
            end.keys.map(&:to_sym)

            missing_keys = required_keys - value.keys.map(&:to_sym)
            if missing_keys.any?
              raise ArgumentError, "Missing required keys in `#{key}` config: #{missing_keys.join(', ')}"
            end

            # Special validation for paste config: lambda must have arity 1
            if key == :paste && value[:lambda]
              unless value[:lambda].arity == 1
                raise ArgumentError, "Expected `paste.lambda` in tiptap_config to accept exactly 1 argument, got arity #{value[:lambda].arity}"
              end
            end
          end
        end

        tiptap_config_hash_or_nil
      else
        {}
      end
    end

    def handle_config!
      @klass.class_variable_set(:@@tiptap_config, @tiptap_config)

      @klass.define_singleton_method :tiptap_config do
        class_variable_get(:@@tiptap_config)
      end
    end

    def setup_html_sanitization_config!
      return if @embed_keys.empty?

      embed_keys = @embed_keys # capture for closure

      @klass.define_method :folio_html_sanitization_config do
        attributes_config = {}

        # Add all embed keys to the sanitization config
        embed_keys.each do |key|
          attributes_config[key] = :unsafe_html
        end

        {
          enabled: true,
          attributes: attributes_config
        }
      end
    end
end
