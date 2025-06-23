# frozen_string_literal: true

class Folio::Tiptap::Node
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.tiptap_node(hash)
    hash.each do |key, type|
      if key == :type
        fail ArgumentError, "Cannot use reserved key `type` in tiptap_node definition"
      end

      handled_type = case type
                     when :string, :text, :jsonb
                     when :rich_text
                       :text
      end

      attribute key, type: handled_type
    end

    define_singleton_method :structure do
      hash
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

  def assign_attributes_from_params(params)
    permitted = self.class.structure.map do |key, type|
      if type == :url_json
        {
          key => %i[href label title rel target],
        }
      else
        key
      end
    end

    attrs = params.require(:tiptap_node_attributes)
                  .permit(*permitted)

    assign_attributes(attrs)
  end

  def self.view_component_class
    "#{self}Component".constantize
  end
end
