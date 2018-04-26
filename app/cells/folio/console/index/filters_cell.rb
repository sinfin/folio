# frozen_string_literal: true

class Folio::Console::Index::FiltersCell < FolioCell
  include ActionView::Helpers::FormOptionsHelper

  def form(&block)
    opts = {
      method: :get,
      'data-auto-submit': true,
    }
    form_tag(controller.request.url, opts, &block)
  end

  def filtered?
    model.keys.any? { |key| controller.params[key].present? }
  end

  def select(key)
    select_tag key, select_options(key),
               include_blank: false,
               class: 'form-control'
  end

  def select_options(key)
    options_for_select(model[key], controller.params[key])
  end
end
