# frozen_string_literal: true

class Folio::Tiptap::NodeBuilder
  def initialize(klass:, structure:, tiptap_config: nil)
    @klass = klass
    @structure = convert_structure_to_hashes(structure)
    @tiptap_config = get_tiptap_config(tiptap_config)
  end

  def build!
    build_structure!
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
        when :collection,
             :string,
             :text
          setup_structure_default(key:)
        when :rich_text
          setup_structure_for_rich_text(key:)
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

    def setup_structure_default(key:)
      @klass.attribute key, type: :text
    end

    def setup_structure_for_rich_text(key:)
      @klass.attribute key, type: :json
      # TODO validate rich_text JSON structure

      @klass.define_method "#{key}=" do |value|
        transformed_value = if value.nil?
          nil
        elsif value.is_a?(String)
          JSON.parse(value) rescue {}
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
          JSON.parse(value) rescue {}
        elsif value.is_a?(Hash)
          value.stringify_keys
        else
          fail ArgumentError, "Expected a String or Hash for #{key}, got #{value.class.name}"
        end

        whitelisted = transformed_value.slice(*::Folio::Tiptap::ALLOWED_URL_JSON_KEYS).transform_values do |v|
          v.is_a?(String) ? v.strip.presence : nil
        end.compact

        super(whitelisted)
      end
    end

    def setup_structure_for_folio_attachment(key:, attr_config:)
      attr_config[:attachment_key]
      class_name = attr_config[:file_type]

      if attr_config[:has_many]
        # Placeholder methods for compatibility with existing code in react_images/react_documents
        @klass.define_method "#{key.to_s.singularize}_placements" do
          send("#{key.to_s.singularize}_ids").map do |file_id|
            attr_config[:placement_class_name].constantize.new(file_id:)
          end
        end

        @klass.define_method "#{key.to_s.singularize}_placements_attributes=" do |attributes|
          ary = []

          if attributes.nil?
            return send("#{key.to_s.singularize}_ids=", [])
          end

          if attributes.is_a?(Hash)
            ary = attributes.values
          elsif attributes.is_a?(Array)
            ary = attributes
          else
            fail ArgumentError, "Expected attributes to be a Hash or Array, got #{attributes.class.name}"
          end

          file_ids = []
          ary.each do |value|
            if value[:file_id] && value[:_destroy] != "1"
              file_ids << value[:file_id].to_i
            end
          end

          send("#{key.to_s.singularize}_ids=", file_ids)
        end

        setup_structure_for_has_many(key:, class_name:)
      else
        # Placeholder methods for compatibility with existing code in Folio::Console::File::PickerCell.
        @klass.define_method "#{key}_placement" do
          file_id = send("#{key}_id")

          if file_id.present?
            attr_config[:placement_class_name].constantize.new(file_id:)
          end
        end

        @klass.define_method "build_#{key}_placement" do
          attr_config[:placement_class_name].constantize.new
        end

        @klass.define_method "#{key}_placement_attributes=" do |attributes|
          if attributes[:_destroy] == "1"
            send("#{key}_id=", nil)
          else
            id = if attributes[:file_id].present?
              if attributes[:file_id].is_a?(String)
                attributes[:file_id].to_i
              elsif attributes[:file_id].is_a?(Integer)
                attributes[:file_id]
              else
                fail ArgumentError, "Expected a String or Integer for file_id, got #{attributes[:file_id].class.name}"
              end
            else
              nil
            end

            send("#{key}_id=", id)
          end
        end

        setup_structure_for_belongs_to(key:, class_name:)
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
              placement_class_name: "Folio::FilePlacement::Cover",
              file_type: "Folio::File::Image",
              has_many: false
            }
          when :document
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              placement_class_name: "Folio::FilePlacement::SingleDocument",
              file_type: "Folio::File::Document",
              has_many: false
            }
          when :audio_cover
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              placement_class_name: "Folio::FilePlacement::AudioCover",
              file_type: "Folio::File::Audio",
              has_many: false
            }
          when :video_cover
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placement".to_sym,
              placement_class_name: "Folio::FilePlacement::VideoCover",
              file_type: "Folio::File::Video",
              has_many: false
            }
          when :images
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placements".to_sym,
              placement_class_name: "Folio::FilePlacement::Image",
              file_type: "Folio::File::Image",
              has_many: true
            }
          when :documents
            result[key] = {
              type: :folio_attachment,
              attachment_key: key,
              placement_key: "#{key.to_s.singularize}_placements".to_sym,
              placement_class_name: "Folio::FilePlacement::Document",
              file_type: "Folio::File::Document",
              has_many: true
            }
          else
            result[key] = { type: value }
          end
        else
          fail ArgumentError, "Expected a Hash, Array or a Symbol for #{key}, got #{value.class.name}"
        end
      end

      result
    end

    TIPTAP_CONFIG_HASH_WHITELIST = {
      use_as_single_image_in_toolbar: [TrueClass, FalseClass],
      autoclick_cover: [TrueClass, FalseClass],
    }

    def get_tiptap_config(tiptap_config_hash_or_nil)
      if tiptap_config_hash_or_nil.is_a?(Hash)
        tiptap_config_hash_or_nil.each do |key, value|
          if value.nil?
            fail ArgumentError, "Expected value for `#{key}` in tiptap_config to be present, got nil"
          end

          if TIPTAP_CONFIG_HASH_WHITELIST[key].nil?
            fail ArgumentError, "Unknown key `#{key}` in tiptap_config. Allowed keys are: #{TIPTAP_CONFIG_HASH_WHITELIST.keys.join(', ')}"
          end

          unless TIPTAP_CONFIG_HASH_WHITELIST[key].any? { |klass| value.is_a?(klass) }
            fail ArgumentError, "Expected value for `#{key}` in tiptap_config to be of type #{TIPTAP_CONFIG_HASH_WHITELIST[key]}, got #{value.class.name}"
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
end
