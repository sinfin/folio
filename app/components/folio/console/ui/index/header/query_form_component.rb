# frozen_string_literal: true

class Folio::Console::Ui::Index::Header::QueryFormComponent < Folio::Console::ApplicationComponent
  include Folio::Console::Component::IndexFilters

  def initialize(klass:, query_url:, query_autocomplete: true, query_filters: nil)
    @klass = klass
    @query_url = query_url
    @query_autocomplete = query_autocomplete
    @query_filters = query_filters
  end

  private
    def data
      stimulus_controller("f-c-ui-index-header-query-form",
                          values: {
                            url: handled_query_url,
                          },
                          action: {
                            "f-input-autocomplete:selected" => "onQueryAutocompleteSelected"
                          })
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

      if handled_query_url
        joiner = handled_query_url.include?("?") ? "&" : "?"
        "#{handled_query_url}#{joiner}#{h.to_query}"
      else
        controller.through_aware_console_url_for(@klass, hash: h)
      end
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
                data: stimulus_action(keypress: "onInputKeypress")
              })
    end

    def query_buttons_kwargs
      submit = {
        variant: :icon,
        icon: :magnify,
        data: stimulus_action(click: "submit")
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
end
