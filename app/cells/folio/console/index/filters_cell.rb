# frozen_string_literal: true

class Folio::Console::Index::FiltersCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def klass
    model[:klass]
  end

  def index_filters
    model[:index_filters]
  end

  def form(&block)
    opts = {
      method: :get,
      url: request.path,
      html: {
        class: 'f-c-index-filters f-c-anti-container-fluid',
        'data-auto-submit' => true,
      }
    }
    simple_form_for '', opts, &block
  end

  def filtered?
    index_filters.keys.any? { |key| controller.params[key].present? }
  end

  def select(f, key)
    f.input key, collection: index_filters[key],
                 include_blank: blank_label(key),
                 selected: controller.params[key],
                 label: false,
                 input_html: { class: 'folio-console-selectize--manual' }
  end

  def select_options(key)
    options_for_select(index_filters[key], controller.params[key])
  end

  def blank_label(key)
    "#{klass.human_attribute_name(key.to_s.gsub(/\Aby_/, ''))}..."
  end
end
