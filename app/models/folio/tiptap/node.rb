# frozen_string_literal: true

class Folio::Tiptap::Node
  include ActiveModel::Model

  include ActiveModel::Attributes
  include ActiveModel::Translation

  def self.tiptap_node(structure:, tiptap_config: nil, nested: false, form_layout: :aside_attachments)
    @nested = nested == true

    Folio::Tiptap::NodeBuilder.new(klass: self,
                                   structure:,
                                   tiptap_config:,
                                   form_layout:).build!
  end

  def self.nested?
    @nested == true
  end

  def logger
    Rails.logger
  end

  def to_tiptap_node_hash
    {
      "type" => "folioTiptapNode",
      "attrs" => to_tiptap_node_attrs,
    }
  end

  def to_tiptap_node_attrs
    {
      "version" => version,
      "type" => self.class.name,
      "data" => tiptap_node_data,
    }
  end

  def tiptap_node_data
    data = {}

    attributes.each do |key, value|
      if value.present? || value == false
        attr_type = self.class.structure.dig(key.to_sym, :type)

        if attr_type == :nested_nodes
          data[key.to_s] = value.map(&:to_tiptap_node_attrs)
        elsif attr_type && attr_type.in?(%i[rich_text url_json]) && value.is_a?(Hash)
          data[key.to_s] = value.to_json
        else
          data[key.to_s] = value
        end
      end
    end

    data
  end

  def version
    1
  end

  def nested_node_instances
    self.class.structure.flat_map do |key, config|
      config[:type] == :nested_nodes ? public_send(key) : []
    end
  end

  def read_attribute_for_validation(attribute)
    return nil if attribute.to_s.include?("[")

    super
  end

  def assign_attributes_from_param_attrs(attrs)
    return if attrs[:data].blank?

    data_attrs = attrs.require(:data)
    permitted = []
    nested_values = {}

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
      when :nested_nodes
        nested_values[key] = data_attrs[key] if data_attrs.key?(key)
      else
        permitted << key
      end
    end

    permitted_data = data_attrs.permit(*permitted)
    nested_values.each do |key, value|
      permitted_data[key] = normalize_nested_param_value(value)
    end

    assign_attributes(permitted_data)
  end

  def self.view_component_class
    "#{self}Component".constantize
  end

  def self.new_from_attributes(attrs, allow_nested: false, expected_class: nil)
    new_from_params(ActionController::Parameters.new(attrs), allow_nested:, expected_class:)
  end

  def self.new_from_params(attrs, allow_nested: false, expected_class: nil)
    klass = attrs.require(:type).safe_constantize

    if klass && klass < Folio::Tiptap::Node
      if klass.nested? && !allow_nested
        fail ArgumentError, "Nested Tiptap node type cannot be used as a top-level node: #{attrs['type']}"
      end

      if expected_class && klass != expected_class
        fail ArgumentError, "Invalid nested Tiptap node type: #{attrs['type']}"
      end

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
          node = new_from_attributes(content["attrs"])
          nodes << node
          nodes.concat(node.nested_node_instances)
        rescue ArgumentError => e
          Rails.logger.error("Folio::Tiptap::Node.instances_from_tiptap_content: #{e.message}")
        end
      elsif content["content"].is_a?(Array) && content["content"].present?
        nodes.concat(instances_from_tiptap_content(content["content"]))
      end
    end

    nodes
  end

  validate :validate_nested_nodes

  private
    def validate_nested_nodes
      return unless self.class.respond_to?(:structure)

      self.class.structure.each do |key, config|
        next unless config[:type] == :nested_nodes

        nested_nodes = Array(public_send(key))

        if nested_nodes.empty?
          errors.add(key, :blank)
          next
        end

        nested_nodes.each_with_index do |nested_node, index|
          next if nested_node.valid?

          nested_node.errors.each do |error|
            errors.add(:"#{key}[#{index}].#{error.attribute}", error.type, **error.options)
          end
        end
      end
    end

    def normalize_nested_param_value(value)
      case value
      when ActionController::Parameters
        value.to_unsafe_h
      when Array
        value.map { |item| normalize_nested_param_value(item) }
      else
        value
      end
    end
end
