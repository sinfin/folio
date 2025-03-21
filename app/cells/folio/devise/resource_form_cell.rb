# frozen_string_literal: true

class Folio::Devise::ResourceFormCell < Folio::Devise::ApplicationCell
  include ActionView::Helpers::FormOptionsHelper
  # to be used in _top and _bottom overrides
  include Folio::Cell::HtmlSafeFieldsFor

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

  def show_subscribed_to_newsletter?(f)
    if model.key?(:show_subscribed_to_newsletter)
      model[:show_subscribed_to_newsletter]
    else
      true
    end
  end

  def show_address?(f)
    return false if model[:hide_address]
    return true if f.object.primary_address.blank?
    return true if f.object.first_name.blank? || f.object.first_name_changed?
    return true if f.object.last_name.blank? || f.object.last_name_changed?
    return false if f.object.primary_address.persisted? && f.object.primary_address.valid? && !f.object.primary_address.changed?
    true
  end
end
