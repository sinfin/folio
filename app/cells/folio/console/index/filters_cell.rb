# frozen_string_literal: true

class Folio::Console::Index::FiltersCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def klass
    model[:klass]
  end

  def index_filters
    @index_filters ||= begin
      h = {}

      model[:index_filters].each do |key, config|
        if config == :date_range
          h[key] = { as: :date_range }
        elsif config.is_a?(Array)
          h[key] = { as: :collection, collection: config }
        elsif config.is_a?(String)
          h[key] = { as: :autocomplete, url: config }
        elsif config.is_a?(Hash)
          h[key] = config
        else
          raise "Invalid index filter type - #{key}"
        end
      end

      h
    end
  end

  def form(&block)
    opts = {
      method: :get,
      url: request.path,
      html: {
        class: "f-c-index-filters #{form_expanded_class_name} f-c-anti-container-fluid",
        "data-auto-submit" => true,
      }
    }
    simple_form_for "", opts, &block
  end

  def form_expanded_class_name
    return nil unless filtered?
    return nil unless has_collapsible?

    if index_filters.any? { |key, config| config[:collapsed] && filtered_by?(key) }
      "f-c-index-filters--expanded"
    end
  end

  def filtered?
    return @filtered unless @filtered.nil?

    @filtered = index_filters.any? do |key, _config|
      filtered_by?(key)
    end
  end

  def collection(key)
    index_filters[key][:collection].map do |value|
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

    if data[:as] == :collection
      collection_input(f, key)
    elsif data[:as] == :date_range
      date_range_input(f, key)
    elsif data[:as] == :text
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
      url = data[:url] || controller.folio.console_api_autocomplete_path(klass: data[:klass],
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
                 wrapper_html: { class: "f-c-index-filters__date-range-input-wrap input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 input_group_append: controller.params[key].present? ? input_group_append : nil,
                 custom_html: content_tag(:span, "date_range", class: "mi mi--16 f-c-index-filters__date-range-input-ico")
  end

  def numeric_range_input(f, key, type:)
    full_key = "#{key}_#{type}".to_sym

    f.input full_key, label: false,
                      input_html: {
                        class: "f-c-index-filters__numeric-range-input",
                        value: controller.params[full_key],
                        autocomplete: "off",
                        placeholder: t(".numeric_range.#{type}"),
                        type: "number",
                      },
                      wrapper: false
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

  def collection_input(f, key)
    f.input key, collection: collection(key),
                 include_blank: blank_label(key),
                 selected: controller.params[key],
                 label: false,
                 wrapper: :input_group,
                 wrapper_html: { class: "input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 input_group_append: controller.params[key].present? ? input_group_append : nil
  end

  def input_group_append
    button_tag("", type: "button", class: "btn fa fa-times f-c-index-filters__reset-input")
  end

  def collapsible_class_name(config)
    if config[:collapsed]
      "f-c-index-filters__filter--collapsible"
    end
  end

  def filter_style(config)
    width = if config[:width]
      if config[:width].is_a?(Numeric)
        "#{config[:width]}px"
      else
        config[:width]
      end
    elsif config[:as] == :numeric_range
      "auto"
    else
      "235px"
    end

    "width: #{width}"
  end

  def filtered_by?(key)
    config = index_filters[key]

    if config[:as] == :numeric_range
      controller.params["#{key}_from"].present? || controller.params["#{key}_to"].present?
    else
      controller.params[key].present?
    end
  end

  def has_collapsible?
    return @has_collapsible unless @has_collapsible.nil?
    @has_collapsible = index_filters.any? { |_key, config| config[:collapsed] }
  end
end
