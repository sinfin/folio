# frozen_string_literal: true

module Folio::RenderComponentJson
  extend ActiveSupport::Concern

  private
    def render_component_json(component, meta: nil, pagy: nil, flash: nil, collection_attribute: nil, status: 200)
      meta_hash = meta || {}

      if pagy
        meta_hash[:pagy] = meta_from_pagy(pagy)
      end

      if flash
        meta_hash[:flash] = flash
      end

      @meta = if meta_hash.present?
        ", \"meta\": #{meta_hash.to_json}"
      end

      if collection_attribute
        @collection = component.to_a.map do |component|
          key = component.instance_variable_get("@#{component.class.collection_parameter}")
          [key.send(collection_attribute), component]
        end

        render "folio/component_collection_json", status:, layout: false
      else
        @component = component
        render "folio/component_json", status:, layout: false
      end
    end

    def render_component_collection_json(component, meta: nil, pagy: nil, flash: nil, attribute: :id, status: 200)
      render_component_json(component, meta:, pagy:, flash:, collection_attribute: attribute, status:)
    end
end
