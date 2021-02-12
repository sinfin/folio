# frozen_string_literal: true

class Folio::Devise::Sessions::NewCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.session_path(resource_name),
      as: resource_name,
      html: { class: "f-devise-sessions-new__form" },
    }

    simple_form_for(resource, opts, &block)
  end
end
