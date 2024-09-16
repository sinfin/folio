# frozen_string_literal: true

class Folio::Console::Index::HeaderCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include Folio::Console::Cell::IndexFilters

  def title
    options[:title] || model.model_name.human(count: 2)
  end

  def query_url
    if options[:query_url].is_a?(String)
      options[:query_url]
    elsif options[:query_url].is_a?(Symbol)
      controller.send(options[:query_url])
    elsif options[:folio_console_merge]
      through_aware_console_url_for(model, action: :merge)
    else
      through_aware_console_url_for(model)
    end
  end

  def query_form(&block)
    opts = {
      url: query_url,
      method: :get,
      html: { class: "f-c-index-header__form" },
    }

    simple_form_for("", opts, &block)
  end

  def query_autocomplete
    return nil if options[:query_autocomplete] == false

    if model.new.respond_to?(:to_label)
      opts = { klass: model.to_s }

      if options[:query_filters]
        options[:query_filters].each do |key, val|
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

    if options[:query_url]
      controller.send(options[:query_url], h)
    elsif options[:folio_console_merge]
      through_aware_console_url_for(model, action: :merge, hash: h)
    else
      through_aware_console_url_for(model, hash: h)
    end
  end

  def csv_path
    if options[:csv] == true
      h = {
        format: :csv,
        by_query: controller.params[:by_query],
      }

      index_filters_hash.keys.each do |key|
        if controller.params[key].present?
          h[key] = controller.params[key]
        end
      end

      safe_url_for(h)
    else
      options[:csv].try(:[], :url) || options[:csv]
    end
  end

  def title_url
    query_url
  end

  def show_transportable_dropdown?
    ::Rails.application.config.folio_show_transportable_frontend &&
    model.try(:transportable?)
  end

  def by_query_input(f)
    f.input(:by_query,
            label: false,
            wrapper: false,
            autocomplete: query_autocomplete,
            input_html: {
              value: params[:by_query],
              id: nil,
              placeholder: options[:by_query_placeholder],
              autocomplete: query_autocomplete ? nil : "off",
            })
  end

  def query_buttons
    submit = cell("folio/console/ui/button",
                  variant: :icon,
                  type: :submit,
                  icon: :magnify)

    if controller.params[:by_query].present?
      [
        cell("folio/console/ui/button",
             variant: :icon,
             href: query_reset_url,
             icon: :close),
        submit
      ]
    else
      [submit]
    end
  end
end
