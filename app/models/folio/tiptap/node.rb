# frozen_string_literal: true

class Folio::Tiptap::Node
  ALLOWED_URL_JSON_KEYS = %w[href label title rel target]

  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.tiptap_node(hash)
    hash.each do |key, type|
      if key == :type
        fail ArgumentError, "Cannot use reserved key `type` in tiptap_node definition"
      end

      if type.is_a?(Hash) && type[:class_name]
        if type[:has_many]
          tiptap_node_setup_structure_for_has_many(key:, class_name: type[:class_name])
        else
          tiptap_node_setup_structure_for_belongs_to(key:, class_name: type[:class_name])
        end
      else
        case type
        when :url_json
          tiptap_node_setup_structure_for_url_json(key:)
        when :image,
             :images,
             :document,
             :documents,
             :audio,
             :video
          tiptap_node_setup_structure_for_attachment(key:, type:)
        when :string,
             :text,
             :rich_text
          tiptap_node_setup_structure_default(key:)
        else
          fail ArgumentError, "Unsupported type #{type} in tiptap_node definition"
        end
      end
    end

    define_singleton_method :structure do
      hash
    end
  end

  def self.tiptap_node_setup_structure_default(key:)
    attribute key, type: :text
  end

  def self.tiptap_node_setup_structure_for_url_json(key:)
    attribute key, type: :json

    define_method "#{key}=" do |value|
      transformed_value = if value.is_a?(String)
        JSON.parse(value) rescue {}
      elsif value.is_a?(Hash)
        value.stringify_keys
      else
        fail ArgumentError, "Expected a String or Hash for #{key}, got #{value.class.name}"
      end

      whitelisted = transformed_value.slice(*ALLOWED_URL_JSON_KEYS).transform_values do |v|
        v.is_a?(String) ? v.strip.presence : nil
      end.compact

      super(whitelisted)
    end
  end

  def self.tiptap_node_setup_structure_for_attachment(key:, type:)
    class_name = folio_attachments_file_class(type:).to_s
    is_plural = type.to_s.end_with?("s")

    if is_plural
      # Placeholder methods for compatibility with existing code in react_images/react_documents
      define_method "#{key.to_s.singularize}_placements" do
        send("#{key}_ids").map do |file_id|
          self.class.folio_attachments_file_placements_class(type:).new(file_id:)
        end
      end

      define_method "#{key.to_s.singularize}_placements_attributes=" do |attributes|
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

        send("#{key}_ids=", file_ids)
      end

      tiptap_node_setup_structure_for_has_many(key:, class_name:)
    else
      # Placeholder methods for compatibility with existing code in Folio::Console::File::PickerCell.
      define_method "#{key}_placement" do
        file_id = send("#{key}_id")

        if file_id.present?
          self.class.folio_attachments_file_placements_class(type:).new(file_id:)
        end
      end

      define_method "build_#{key}_placement" do
        self.class.folio_attachments_file_placements_class(type:).new
      end

      define_method "#{key}_placement_attributes=" do |attributes|
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

      tiptap_node_setup_structure_for_belongs_to(key:, class_name:)
    end
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

  def self.tiptap_node_setup_structure_for_belongs_to(key:, class_name:)
    attribute "#{key}_id", type: :integer
    klass = class_name.constantize

    define_method(key) do
      klass.find_by(id: send("#{key}_id"))
    end

    # always cast ids to integers when setting them
    define_method("#{key}_id=") do |raw_value|
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

    define_method("#{key}=") do |value|
      if value.is_a?(klass)
        send("#{key}_id=", value.id)
      else
        fail ArgumentError, "Expected a #{klass.name} for #{key}, got #{value.class.name}"
      end
    end
  end

  def self.tiptap_node_setup_structure_for_has_many(key:, class_name:)
    attribute "#{key}_ids", type: :integer, array: true, default: []
    klass = class_name.constantize

    define_method(key) do
      ids = send("#{key}_ids")

      if ids.present?
        klass.where(id: ids).to_a
      else
        []
      end
    end

    # always cast ids to integers when setting them
    define_method("#{key}_ids=") do |raw_ary|
      raw_ary ||= []

      unless raw_ary.is_a?(Array)
        fail ArgumentError, "Expected an Array for #{key}_ids, got #{raw_ary.class.name}"
      end

      ary = []

      raw_ary.each do |raw_value|
        if raw_value.present?
          if raw_value.is_a?(String)
            ary << raw_value.to_i
          elsif raw_value.is_a?(Integer)
            ary << raw_value
          else
            fail ArgumentError, "Expected a String or Integer for #{key}_ids, got #{raw_value.class.name}"
          end
        end
      end

      super(ary)
    end

    define_method("#{key}=") do |value|
      if value.is_a?(Array) && value.all? { |v| v.is_a?(klass) }
        send("#{key}_ids=", value.map(&:id))
      else
        fail ArgumentError, "Expected an Array of #{klass.name} for #{key}, got #{value}"
      end
    end
  end

  def to_tiptap_node_hash
    data = {}

    attributes.each do |key, value|
      if value.present?
        data[key.to_s] = value
      end
    end

    {
      "type" => "folioTiptapNode",
      "attrs" => {
        "version" => version,
        "type" => self.class.name,
        "data" => data,
      },
    }
  end

  def version
    1
  end

  def assign_attributes_from_param_attrs(attrs)
    return if attrs[:data].blank?

    permitted = []

    self.class.structure.each do |key, type|
      case type
      when :url_json
        permitted << key
        permitted << { key => ALLOWED_URL_JSON_KEYS }
      when :image, :document, :audio, :video
        permitted << "#{key}_id"
        permitted << { "#{key}_placement_attributes" => %i[file_id _destroy] }
      when :images, :documents
        permitted << "#{key}_ids"
        permitted << { "#{key.to_s.singularize}_placements_attributes" => %i[file_id _destroy] }
      when Hash
        if type[:class_name]
          if type[:has_many]
            permitted << "#{key}_ids"
          else
            permitted << "#{key}_id"
          end
        end
      else
        permitted << key
      end
    end

    permitted_data = attrs.require(:data).permit(*permitted)
    assign_attributes(permitted_data)
  end

  def self.view_component_class
    "#{self}Component".constantize
  end

  def self.new_from_attrs(attrs)
    klass = attrs.require(:type).safe_constantize

    if klass && klass < Folio::Tiptap::Node
      node = klass.new
      node.assign_attributes_from_param_attrs(attrs)
      node
    else
      fail ArgumentError, "Invalid Tiptap node type: #{attrs['type']}"
    end
  end
end
