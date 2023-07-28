# frozen_string_literal: true

class Folio::Console::Index::FiltersCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper
  include Folio::Console::Cell::IndexFilters

  def klass
    model[:klass]
  end

  def form(&block)
    opts = {
      method: :get,
      url: request.path,
      html: {
        class: "f-c-index-filters #{form_expanded_class_name} f-c-anti-container-fluid f-c-anti-container-fluid--padded",
        "data-auto-submit" => true,
      }
    }
    simple_form_for "", opts, &block
  end

  def form_expanded_class_name
    return nil unless filtered?
    return nil unless has_collapsible?

    if index_filters_hash.any? { |key, config| config[:collapsed] && filtered_by?(key) }
      "f-c-index-filters--expanded"
    end
  end

  def collection(key)
    index_filters_hash[key][:collection].map do |value|
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
    data = index_filters_hash[key]

    id_method = if data[:id_method] && data[:klass].constantize.column_names.include?(data[:id_method].to_s)
      data[:id_method].to_s
    end

    if data[:as] == :collection
      collection_input(f, key)
    elsif data[:as] == :date_range
      date_range_input(f, key)
    elsif data[:as] == :hidden
      hidden_input(f, key)
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
                                                                         slug: data[:slug],
                                                                         id_method:)
      autocomplete_input(f, key, url:)
    else
      url = controller.folio.select2_console_api_autocomplete_path(klass: data[:klass],
                                                                   scope: data[:scope],
                                                                   order_scope: data[:order_scope],
                                                                   slug: data[:slug],
                                                                   id_method:,
                                                                   label_method: data[:label_method])

      select2_select(f, key, data, url:)
    end
  end

  def date_range_input(f, key)
    f.input key, label: false,
                 as: :date_range,
                 input_html: {
                   class: "f-c-index-filters__date-range-input",
                   value: controller.params[key],
                   placeholder: "#{label_for_key(key)}...",
                 },
                 wrapper: :input_group,
                 wrapper_html: { class: "f-c-index-filters__date-range-input-wrap input-group--#{controller.params[key].present? ? "filled" : "empty"}" },
                 input_group_append: controller.params[key].present? ? input_group_append : nil
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
      klass = data[:klass].constantize

      if data[:id_method] && klass.column_names.include?(data[:id_method].to_s)
        record = klass.find_by(data[:id_method] => controller.params[key])
        collection << [record.to_console_label, record.send(data[:id_method]), selected: true] if record
      elsif data[:slug]
        record = klass.find_by_slug(controller.params[key])
        collection << [record.to_console_label, record.slug, selected: true] if record
      else
        record = klass.find_by_id(controller.params[key])
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
    cell("folio/console/ui/button",
         class: "f-c-index-filters__reset-input",
         variant: :medium_dark,
         icon: :close)
  end

  def collapsible_class_name(config)
    if config[:collapsed]
      "f-c-index-filters__filter--collapsible"
    end
  end

  def filter_style(config, filtered: false)
    width = if config[:width]
      if config[:width].is_a?(Numeric)
        "#{config[:width]}px"
      else
        config[:width]
      end
    elsif config[:as] == :numeric_range
      "auto"
    elsif filtered && config[:as] == :date_range
      "250px"
    else
      "235px"
    end

    "width: #{width}"
  end

  def has_collapsible?
    return @has_collapsible unless @has_collapsible.nil?
    @has_collapsible = index_filters_hash.any? { |_key, config| config[:collapsed] }
  end

  def hidden_input(f, key, config)
    if !config[:value].nil? || controller.params[key].present?
      f.hidden_field key, value: config[:value].nil? ? controller.params[key] : config[:value]
    end
  end
end
