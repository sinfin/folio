# frozen_string_literal: true

class Folio::Tiptap::NodeBuilder
  def initialize(klass:, structure:)
    @klass = klass
    @structure = structure
  end

  def build!
    build_structure!
  end

  def self.folio_attachments_file_class(type:)
    case type
    when :image, :images
      Folio::File::Image
    when :document, :documents
      Folio::File::Document
    when :audio
      Folio::File::Audio
    when :video
      Folio::File::Video
    else
      fail ArgumentError, "Unsupported attachment type #{type}"
    end
  end

  def self.folio_attachments_file_placements_class(type:)
    case type
    when :image
      Folio::FilePlacement::Cover
    when :images
      Folio::FilePlacement::Image
    when :document
      Folio::FilePlacement::SingleDocument
    when :documents
      Folio::FilePlacement::Document
    when :audio
      Folio::FilePlacement::AudioCover
    when :video
      Folio::FilePlacement::VideoCover
    else
      fail ArgumentError, "Unsupported attachment type #{type}"
    end
  end

  private
    def build_structure!
      @structure.each do |key, type|
        if key == :type
          fail ArgumentError, "Cannot use reserved key `type` in tiptap_node definition"
        end

        if type.is_a?(Hash) && type[:class_name]
          if type[:has_many]
            setup_structure_for_has_many(key:, class_name: type[:class_name])
          else
            setup_structure_for_belongs_to(key:, class_name: type[:class_name])
          end
        else
          case type
          when :url_json
            setup_structure_for_url_json(key:)
          when :image,
               :images,
               :document,
               :documents,
               :audio,
               :video
            setup_structure_for_attachment(key:, type:)
          when :string,
               :text,
               :rich_text
            setup_structure_default(key:)
          else
            fail ArgumentError, "Unsupported type #{type} in tiptap_node definition"
          end
        end
      end

      @klass.class_variable_set(:@@structure, @structure)

      @klass.define_singleton_method :structure do
        class_variable_get(:@@structure)
      end
    end

    def setup_structure_default(key:)
      @klass.attribute key, type: :text
    end

    def setup_structure_for_url_json(key:)
      @klass.attribute key, type: :json

      @klass.define_method "#{key}=" do |value|
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

    def setup_structure_for_attachment(key:, type:)
      class_name = self.class.folio_attachments_file_class(type:).to_s
      is_plural = type.to_s.end_with?("s")

      if is_plural
        # Placeholder methods for compatibility with existing code in react_images/react_documents
        @klass.define_method "#{key.to_s.singularize}_placements" do
          send("#{key.to_s.singularize}_ids").map do |file_id|
            Folio::Tiptap::NodeBuilder.folio_attachments_file_placements_class(type:).new(file_id:)
          end
        end

        @klass.define_method "#{key.to_s.singularize}_placements_attributes=" do |attributes|
          ary = []

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
            Folio::Tiptap::NodeBuilder.folio_attachments_file_placements_class(type:).new(file_id:)
          end
        end

        @klass.define_method "build_#{key}_placement" do
          Folio::Tiptap::NodeBuilder.folio_attachments_file_placements_class(type:).new
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
        if value.is_a?(belongs_to_klass)
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
end
