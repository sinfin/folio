# frozen_string_literal: true

module Folio::DeviseExtension
  extend ActiveSupport::Concern

  included do
    layout :layout_by_resource
  end

  def layout_by_resource
    if resource_name == :account
      "folio/console/devise"
    else
      "devise"
    end
  end
end
