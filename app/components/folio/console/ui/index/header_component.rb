# frozen_string_literal: true

class Folio::Console::Ui::Index::HeaderComponent < Folio::Console::ApplicationComponent
  include Folio::Console::Component::IndexFilters

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

      controller.try(:safe_url_for, h)
    else
      @csv.try(:[], :url) || @csv
    end
  end

  def handled_query_url
    @handled_query_url ||= if @query_url.is_a?(String)
      @query_url
    elsif @query_url.is_a?(Symbol)
      send(@query_url)
    else
      request.path
    end
  end

  def title_url
    handled_query_url
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
