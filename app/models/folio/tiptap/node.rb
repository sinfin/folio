# frozen_string_literal: true

class Folio::Tiptap::Node
  include ActiveModel::Model

  include ActiveModel::Attributes
  include ActiveModel::Translation

  def self.tiptap_node(structure:, tiptap_config: nil)
    Folio::Tiptap::NodeBuilder.new(klass: self,
                                   structure:,
                                   tiptap_config:).build!
  end

  def logger
    Rails.logger
  end

  def to_tiptap_node_hash
    data = {}

    attributes.each do |key, value|
      if value.present?
        attr_type = self.class.structure.dig(key.to_sym, :type)

        if attr_type && attr_type.in?(%i[rich_text url_json]) && value.is_a?(Hash)
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

    self.class.structure.each do |key, attr_config|
      case attr_config[:type]
      when :url_json
        permitted << key
        permitted << { key => ::Folio::Tiptap::ALLOWED_URL_JSON_KEYS }
      when :folio_attachment
        strong_params = [
          :file_id,
          :title,
          :alt,
          :description,
          :position,
          :_destroy,
          :folio_embed_data,
          folio_embed_data: Folio::Embed.hash_strong_params_keys,
        ]

        if attr_config[:has_many]
          permitted << { "#{key.to_s.singularize}_ids" => [] }
          permitted << { "#{key.to_s.singularize}_placements_attributes" => strong_params }
        else
          permitted << "#{key}_id"
          permitted << { "#{key}_placement_attributes" => strong_params }
        end
      when :relation
        if attr_config[:has_many]
          permitted << { "#{key.to_s.singularize}_ids" => [] }
        else
          permitted << "#{key}_id"
        end
      when :embed
        permitted += [
          key,
          { key => Folio::Embed.hash_strong_params_keys },
        ]
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

  def self.new_from_attributes(attrs)
    new_from_params(ActionController::Parameters.new(attrs))
  end

  def self.new_from_params(attrs)
    klass = attrs.require(:type).safe_constantize

    if klass && klass < Folio::Tiptap::Node
      node = klass.new
      node.assign_attributes_from_param_attrs(attrs)
      node
    else
      fail ArgumentError, "Invalid Tiptap node type: #{attrs['type']}"
    end
  end

  def self.sti_paths
    [
      Rails.root.join("app/models/**/tiptap/node"),
    ]
  end

  def self.instances_from_tiptap_content(content)
    nodes = []

    if content.is_a?(Array)
      content.each do |node|
        nodes.concat(instances_from_tiptap_content(node))
      end
    elsif content.is_a?(Hash)
      if content["type"] == "folioTiptapNode"
        begin
          nodes << new_from_attributes(content["attrs"])
        rescue ArgumentError => e
          Rails.logger.error("Folio::Tiptap::Node.instances_from_tiptap_content: #{e.message}")
        end
      elsif content["content"].is_a?(Array) && content["content"].present?
        nodes.concat(instances_from_tiptap_content(content["content"]))
      end
    end

    nodes
  end
end
