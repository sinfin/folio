# frozen_string_literal: true

class Folio::Tiptap::Node
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.tiptap_node(structure:)
    Folio::Tiptap::NodeBuilder.new(klass: self, structure:).build!
  end

  def to_tiptap_node_hash
    data = {}

    attributes.each do |key, value|
      if value.present?
        key_definition = self.class.structure[key.to_sym]

        if key_definition && key_definition.in?(%i[rich_text url_json]) && value.is_a?(Hash)
          data[key.to_s] = value.to_json
        else
          data[key.to_s] = value
        end
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
        permitted << { key => ::Folio::Tiptap::ALLOWED_URL_JSON_KEYS }
      when :image, :document, :audio, :video
        permitted << "#{key}_id"
        permitted << { "#{key}_placement_attributes" => %i[file_id _destroy] }
      when :images, :documents
        permitted << { "#{key.to_s.singularize}_ids" => [] }
        permitted << { "#{key.to_s.singularize}_placements_attributes" => %i[file_id _destroy] }
      when Hash
        if type[:class_name]
          if type[:has_many]
            permitted << { "#{key.to_s.singularize}_ids" => [] }
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
