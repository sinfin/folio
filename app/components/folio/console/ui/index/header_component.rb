# frozen_string_literal: true

class Folio::Console::Ui::Index::HeaderComponent < Folio::Console::ApplicationComponent
  include Folio::Console::Cell::IndexFilters

  bem_class_name :subtitle

  renders_one :right_content
  renders_one :content_above_filters

  def initialize(klass:,
                 title: nil,
                 subtitle: nil,
                 pagy: nil,
                 pagy_options: nil,
                 tabs: nil,
                 csv: nil,
                 by_label_query: true,
                 file_list_uppy: nil,
                 query_url: nil,
                 query_autocomplete: nil,
                 query_filters: nil,
                 types: nil,
                 new_button: true)
    @klass = klass
    @title = title
    @subtitle = subtitle
    @pagy = pagy
    @pagy_options = pagy_options
    @tabs = tabs
    @csv = csv
    @by_label_query = by_label_query
    @file_list_uppy = file_list_uppy
    @query_url = query_url
    @query_autocomplete = query_autocomplete
    @query_filters = query_filters
    @types = types
    @new_button = new_button
  end

  def title
    @title || @klass.model_name.human(count: 2)
  end

  def query_url
    if @query_url.is_a?(String)
      @query_url
    elsif @query_url.is_a?(Symbol)
      send(@query_url)
    else
      request.path
    end
  end

  def query_form(&block)
    opts = {
      url: query_url,
      method: :get,
      html: {
        class: "f-c-index-header__form",
        data: stimulus_action("f-input-autocomplete:selected" => "onQueryAutocompleteSelected")
      },
    }

    helpers.simple_form_for("", opts, &block)
  end

  def query_autocomplete
    return nil if @query_autocomplete == false

    if @klass.new.respond_to?(:to_label)
      opts = { klass: @klass.to_s }

      if @query_filters
        @query_filters.each do |key, val|
          opts["filter_#{key}"] = val
        end
      end

      controller.folio.console_api_autocomplete_path(opts)
    end
  end

  def query_reset_url
    h = {}

    index_filters_hash.keys.each do |key|
      if controller.params[key].present?
        h[key] = controller.params[key]
      end
    end

    if query_url
      joiner = query_url.include?("?") ? "&" : "?"
      "#{query_url}#{joiner}#{h.to_query}"
    else
      controller.through_aware_console_url_for(@klass, hash: h)
    end
  end

  def csv_path
    if @csv == true
      h = {
        format: :csv,
        by_label_query: controller.params[:by_label_query],
      }

      index_filters_hash.keys.each do |key|
        if controller.params[key].present?
          h[key] = controller.params[key]
        end
      end

      safe_url_for(h)
    else
      @csv.try(:[], :url) || @csv
    end
  end

  def title_url
    query_url
  end

  def by_label_query_input(f)
    f.input(:by_label_query,
            label: false,
            wrapper: false,
            autocomplete: query_autocomplete,
            input_html: {
              value: params[:by_label_query],
              id: nil,
              autocomplete: query_autocomplete ? nil : "off",
            })
  end

  def query_buttons_kwargs
    submit = {
      variant: :icon,
      type: :submit,
      icon: :magnify
    }

    if controller.params[:by_label_query].present?
      close = {
        variant: :icon,
        href: query_reset_url,
        icon: :close
      }

      [close, submit]
    else
      [submit]
    end
  end

  def has_visible_index_filters?
    index_filters.present? && index_filters.any? do |key, hash|
      !hash.is_a?(Hash) || (hash.try(:[], :as) != :hidden)
    end
  end

  def data
    stimulus_controller("f-c-ui-index-header")
  end
end
