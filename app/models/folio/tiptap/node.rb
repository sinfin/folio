# frozen_string_literal: true

class Folio::Tiptap::Node
  include ActiveModel::Model

  include ActiveModel::Attributes
  include ActiveModel::Translation

  attr_accessor :site

  validate :validate_site_attachment_allowed

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

  def self.new_from_attributes(attrs, site: nil)
    new_from_params(ActionController::Parameters.new(attrs), site: site)
  end

  def self.new_from_params(attrs, site: nil)
    klass = attrs.require(:type).safe_constantize

    if klass && klass < Folio::Tiptap::Node
      node = klass.new
      node.site = site
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

  private
    def validate_site_attachment_allowed
      structure = self.class.respond_to?(:structure) && self.class.structure
      return unless @site && structure

      has_invalid_attachment = structure.any? do |key, cfg|
        next false unless cfg[:type] == :folio_attachment
        next false unless (file_klass = cfg[:file_type]&.safe_constantize)

        if cfg[:has_many]
          placements = send("#{key.to_s.singularize}_placements_attributes") || []
          placements.any? { |h| file_invalid_for_site?(h, file_klass, @site) }
        else
          placement = send("#{key}_placement_attributes")
          file_invalid_for_site?(placement, file_klass, @site)
        end
      end

      errors.add(:base, I18n.t("folio.tiptap.errors.file_not_allowed_for_site")) if has_invalid_attachment
    rescue StandardError => e
      Rails.logger.error("Folio::Tiptap site validation error: #{e.message}") if defined?(Rails)
    end

    def file_invalid_for_site?(placement_hash, file_klass, site)
      return false unless placement_hash

      file_id = placement_hash["file_id"] || placement_hash[:file_id]
      return false unless file_id

      file = file_klass.find_by(id: file_id)
      file && !file.can_be_used_on_site?(site)
    end
end
