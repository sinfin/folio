# frozen_string_literal: true

module Folio::RenderComponentJson
  extend ActiveSupport::Concern

  private
    def render_component_json(component, pagy: nil, flash: nil, collection_attribute: nil, status: 200)
      meta = {}

      if pagy
        meta[:pagy] = meta_from_pagy(pagy)
      end

      if flash
        meta[:flash] = flash
      end

      @meta = if meta.present?
        ", \"meta\": #{meta.to_json}"
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

    def render_component_collection_json(component, pagy: nil, flash: nil, attribute: :id, status: 200)
      render_component_json(component, pagy:, flash:, collection_attribute: attribute, status:)
    end
end
