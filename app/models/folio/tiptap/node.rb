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
    is_plural = type.to_s.end_with?("s")
    singular_type = is_plural ? type.to_s.chomp("s") : type.to_s

    class_name = case singular_type
                 when "image"
                   "Folio::File::Image"
                 when "document"
                   "Folio::File::Document"
                 when "audio"
                   "Folio::File::Audio"
                 when "video"
                   "Folio::File::Video"
                 else
                   fail ArgumentError, "Unsupported attachment type for type #{type}"
    end

    if is_plural
      tiptap_node_setup_structure_for_has_many(key:, class_name:)
    else
      # Placeholder methods for compatibility with existing code in Folio::Console::File::PickerCell.
      define_method "#{key}_placement" do
        self.class.folio_attachments_file_placements_class(key:).new(file_id: send("#{key}_id"), file_type: class_name)
      end

      # def tiptap_node_pseudo_file_placements
      #   []
      # end
      tiptap_node_setup_structure_for_belongs_to(key:, class_name:)
    end
  end

  def self.folio_attachments_file_placements_class(key:)
    case key
    when :image
      Folio::FilePlacement::Cover
    when :document
      Folio::FilePlacement::SingleDocument
    when :audio
      Folio::FilePlacement::AudioCover
    when :video
      Folio::FilePlacement::VideoCover
    else
      fail ArgumentError, "Unsupported attachment key #{key}"
    end
  end

  def self.tiptap_node_setup_structure_for_belongs_to(key:, class_name:)
    attribute "#{key}_id", type: :integer
    klass = class_name.constantize

    define_method(key) do
      klass.find_by(id: send("#{key}_id"))
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
      klass.where(id: send("#{key}_ids")).to_a
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
      if type == :url_json
        permitted << key
        permitted << { key => ALLOWED_URL_JSON_KEYS }
      else
        permitted << key
      end
    end

    assign_attributes(attrs.require(:data).permit(*permitted))
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
