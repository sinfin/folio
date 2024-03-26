# frozen_string_literal: true

module Folio::FormsHelper
  def folio_nested_fields(f, key, add: true, destroy: true, &block)
    render(Folio::NestedFieldsComponent.new(f:, key:, add:, destroy:)) do |c|
      block.call(c.g)
    end
  end
end
