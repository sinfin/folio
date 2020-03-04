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
    if index_filters[key].is_a?(String)
      f.input key, label: false,
                   input_html: {
                     class: 'f-c-index-filters__autocomplete-input',
                     'data-url' => index_filters[key],
                     'data-controller' => controller.class.to_s.underscore,
                     placeholder: blank_label(key),
                     value: controller.params[key]
                   },
                   wrapper_html: {
                    class: 'f-c-index-filters__autocomplete-wrap'
                   }
    else
      f.input key, collection: collection(key),
                   include_blank: blank_label(key),
                   selected: controller.params[key],
                   label: false
    end
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
    url_for([:console, klass, by_query: controller.params[:by_query]])
  end
end
