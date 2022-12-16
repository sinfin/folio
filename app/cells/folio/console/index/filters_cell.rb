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
        class: "f-c-index-filters f-c-anti-container-fluid",
        "data-auto-submit" => true,
      }
    }
    simple_form_for "", opts, &block
  end

  def filtered?
    index_filters.keys.any? { |key| controller.params[key].present? }
  end

  def collection(key)
    index_filters[key].map do |value|
      if value == true
        [t("true"), true]
      elsif value == false
        [t("false"), false]
      elsif !value.is_a?(Array)
        [value, value]
      else
        value
      end
    end
  end

  def blank_label(key)
    "#{label_for_key(key)}..."
  end

  def label_for_key(key)
    clear_key = key.to_s
                   .delete_prefix("by_")
                   .delete_suffix("_query")
                   .delete_suffix("_id")
                   .delete_suffix("_slug")

    klass.human_attribute_name(clear_key)
  end

  def cancel_url
    model[:cancel_url] ||
    request.path
  end

  def input(f, key)
    data = index_filters[key]

    if data.is_a?(String)
      autocomplete_input(f, key, url: data)
    elsif data.is_a?(Hash)
      if data[:as] == :text
        if data[:autocomplete_attribute]
          url = Folio::Engine.app.url_helpers.url_for([
            :field,
            :console,
            :api,
            :autocomplete,
            klass: data[:autocomplete_klass] || controller.instance_variable_get("@klass"),
            scope: data[:scope].presence,
            order_scope: data[:order_scope].presence,
            field: data[:autocomplete_attribute],
            only_path: true,
          ].compact)

          text_autocomplete_input(f, key, url:)
        else
          text_input(f, key)
        end
      elsif data[:autocomplete]
        url = controller.folio.console_api_autocomplete_path(klass: data[:klass],
                                                             scope: data[:scope],
                                                             order_scope: data[:order_scope],
                                                             slug: data[:slug])
        autocomplete_input(f, key, url:)
      else
        url = controller.folio.select2_console_api_autocomplete_path(klass: data[:klass],
                                                                     scope: data[:scope],
                                                                     order_scope: data[:order_scope],
                                                                     slug: data[:slug],
                                                                     label_method: data[:label_method])
        select2_select(f, key, data, url:)
      end
    else
      f.input key, collection: collection(key),
                   include_blank: blank_label(key),
                   selected: controller.params[key],
                   label: false,
                   wrapper: :input_group,
                   wrapper_html: { class: "input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                   input_group_append: controller.params[key].present? ? input_group_append : nil
    end
  end

  def date_range_input(f, key)
    f.input key, label: false,
                 input_html: {
                   class: "f-c-index-filters__date-range-input",
                   value: controller.params[key],
                   autocomplete: "off",
                   placeholder: "#{label_for_key(key)}...",
                 },
                 wrapper: :input_group,
                 wrapper_html: { class: "input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 input_group_append: controller.params[key].present? ? input_group_append : nil
  end

  def text_input(f, key)
    f.input key, label: false,
                 input_html: {
                   class: "f-c-index-filters__text-input",
                   placeholder: blank_label(key),
                   value: controller.params[key]
                 },
                 wrapper_html: { class: "f-c-index-filters__text-input-wrap input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 wrapper: :input_group,
                 input_group_append: controller.params[key].present? ? input_group_append : nil
  end

  def text_autocomplete_input(f, key, url:)
    f.input key, label: false,
                 input_html: {
                   class: "f-c-index-filters__text-autocomplete-input",
                   "data-url" => url,
                   "data-controller" => controller.class.to_s.underscore,
                   placeholder: "#{label_for_key(key)}...",
                   value: controller.params[key],
                   autocomplete: "off",
                 },
                 wrapper_html: { class: "f-c-index-filters__text-autocomplete-wrap input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 wrapper: :input_group,
                 input_group_append: controller.params[key].present? ? input_group_append : nil
  end

  def autocomplete_input(f, key, url:)
    f.input key, label: false,
                 input_html: {
                   class: "f-c-index-filters__autocomplete-input",
                   "data-url" => url,
                   "data-controller" => controller.class.to_s.underscore,
                   placeholder: blank_label(key),
                   value: controller.params[key]
                 },
                 wrapper_html: { class: "f-c-index-filters__autocomplete-wrap input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 wrapper: :input_group,
                 input_group_append: controller.params[key].present? ? input_group_append : nil
  end

  def select2_select(f, key, data, url:)
    collection = []

    if controller.params[key].present?
      if data[:slug]
        record = data[:klass].constantize.find_by_slug(controller.params[key])
        collection << [record.to_console_label, record.slug, selected: true] if record
      else
        record = data[:klass].constantize.find_by_id(controller.params[key])
        collection << [record.to_console_label, record.id, selected: true] if record
      end
    end

    f.input key, collection:,
                 force_collection: true,
                 label: false,
                 remote: url,
                 input_html: {
                   class: "f-c-index-filters__select2-input",
                   "data-placeholder" => "#{label_for_key(key)}...",
                 },
                 wrapper_html: { class: "f-c-index-filters__select2-wrap input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 wrapper: :input_group,
                 input_group_append: controller.params[key].present? ? input_group_append : nil
  end

  def input_group_append
    button_tag("", type: "button", class: "btn fa fa-times f-c-index-filters__reset-input")
  end
end
