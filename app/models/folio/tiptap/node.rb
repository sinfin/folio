# frozen_string_literal: true

class Folio::Tiptap::Node
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.tiptap_node(hash)
    attr_accessor(*hash.keys)

    define_singleton_method :structure do
      hash
    end
  end

  def to_tiptap_node_hash
    {
      yee: "haw",
    }
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

    attributes = params.require(:tiptap_node_attributes)
                       .permit(*permitted)

    assign_attributes(attributes)
  end
end
