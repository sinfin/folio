# frozen_string_literal: true

class Folio::Devise::ResourceFormCell < Folio::Devise::ApplicationCell
  include ActionView::Helpers::FormOptionsHelper

  def form(&block)
    opts = {
      url: model[:form_url],
      as: resource_name,
      html: {
        class: model[:modal] ? "f-devise-modal__form" : nil,
        id: nil
      },
    }

    simple_form_for(resource, opts, &block)
  end
end
