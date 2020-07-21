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

  def collection(key)
    base = index_filters[key].map do |value|
      if value == true
        [t('true'), true]
      elsif value == false
        [t('false'), false]
      elsif !value.is_a?(Array)
        [value, value]
      else
        value
      end
    end

    if controller.params[key].present?
      base.map do |label, value|
        [
          "#{label_for_key(key)} - #{label}",
          value,
        ]
      end
    else
      base
    end
  end

  def blank_label(key)
    if controller.params[key].present?
      "× #{t('folio.console.actions.cancel')}"
    else
      "#{label_for_key(key)}..."
    end
  end

  def label_for_key(key)
    clear_key = key.to_s.gsub(/\Aby_/, '').gsub(/_query\z/, '')
    klass.human_attribute_name(clear_key)
  end

  def cancel_url
    model[:cancel_url] ||
    request.path
  end

  def date_range_input(f, key)
    f.input key, label: false,
                 input_html: {
                   class: 'f-c-index-filters__date-range-input',
                   value: controller.params[key],
                   autocomplete: 'off',
                   placeholder: t(".placeholders.#{key}", default: ''),
                 },
                 wrapper: false
  end

  def select(f, key)
    data = index_filters[key]

    if data.is_a?(String)
      autocomplete_select(f, key, url: data)
    elsif data.is_a?(Hash)
      url = controller.folio.console_api_autocomplete_path(klass: data[:klass],
                                                           scope: data[:scope],
                                                           order_scope: data[:order_scope])
      autocomplete_select(f, key, url: url)
    else
      f.input key, collection: collection(key),
                   include_blank: blank_label(key),
                   selected: controller.params[key],
                   label: false
    end
  end

  def autocomplete_select(f, key, url:)
    f.input key, label: false,
                 input_html: {
                   class: 'f-c-index-filters__autocomplete-input',
                   'data-url' => url,
                   'data-controller' => controller.class.to_s.underscore,
                   placeholder: blank_label(key),
                   value: controller.params[key]
                 },
                 wrapper_html: {
                   class: 'f-c-index-filters__autocomplete-wrap'
                 }
  end
end
