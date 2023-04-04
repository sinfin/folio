# frozen_string_literal: true

class Folio::Console::Index::HeaderCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def title
    options[:title] || model.model_name.human(count: 2)
  end

  def query_url
    if options[:query_url]
      send(options[:query_url])
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

    controller.send(:index_filters).keys.each do |key|
      if controller.params[key].present?
        h[key] = controller.params[key]
      end
    end

    if options[:query_url]
      send(options[:query_url], h)
    elsif options[:folio_console_merge]
      through_aware_console_url_for(model, action: :merge, hash: h)
    else
      through_aware_console_url_for(model, hash: h)
    end
  end

  def new_button(&block)
    url = options[:new_url] ? send(options[:new_url]) : through_aware_console_url_for(model, action: :new, safe: true)

    if url
      html_opts = { title: t(".add"),
                    class: "btn btn-success "\
                           "f-c-index-header__btn f-c-index-header__btn--new" }

      link_to(url, html_opts, &block)
    end
  end

  def new_dropdown_title
    render(:_new_dropdown_title)
  end

  def new_dropdown_links
    options[:new_dropdown_links] || options[:types].map do |klass|
      {
        title: klass.model_name.human,
        url: through_aware_console_url_for(model, action: :new, hash: { type: klass.to_s }, safe: true),
      }
    end
  end

  def csv_path
    if options[:csv] == true
      h = {
        format: :csv,
        by_query: controller.params[:by_query],
      }

      controller.send(:index_filters).keys.each do |key|
        if controller.params[key].present?
          h[key] = controller.params[key]
        end
      end

      through_aware_console_url_for(model, hash: h)
    else
      options[:csv].try(:[], :url) || options[:csv]
    end
  end

  def title_url
    options[:query_url] ? send(options[:query_url]) : through_aware_console_url_for(model)
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
              placeholder: options[:by_query_placeholder]
            })
  end
end
