# frozen_string_literal: true

class Folio::Console::Index::HeaderCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def title
    model.model_name.human(count: 2)
  end

  def query_url
    if options[:folio_console_merge]
      url_for([:merge, :console, model])
    else
      url_for([:console, model])
    end
  end

  def query_form(&block)
    opts = {
      url: query_url,
      method: :get,
      html: { class: 'f-c-index-header__form' },
    }

    simple_form_for('', opts, &block)
  end

  def query_autocomplete
    if model.new.respond_to?(:to_label)
      controller.console_api_autocomplete_path(klass: model.to_s)
    end
  end

  def query_reset_url
    h = {}

    controller.send(:index_filters).keys.each do |key|
      if controller.params[key].present?
        h[key] = controller.params[key]
      end
    end

    if options[:folio_console_merge]
      url_for([:merge, :console, model, h])
    else
      url_for([:console, model, h])
    end
  end

  def new_button(&block)
    url = url_for([:console, model, action: :new])
    html_opts = { title: t('.add'),
                  class: 'btn btn-success '\
                         'f-c-index-header__btn f-c-index-header__btn--new' }
    link_to(url, html_opts, &block)
  rescue NoMethodError
  end

  def new_dropdown_title
    render(:_new_dropdown_title)
  end

  def new_dropdown_links
    options[:types].map do |klass|
      {
        title: klass.model_name.human,
        url: url_for([:console, model, action: :new, type: klass.to_s])
      }
    end
  end

  def csv_path
    url_for([:console, model, format: :csv])
  end
end
