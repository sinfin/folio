# frozen_string_literal: true

class Folio::Console::Index::HeaderCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def title
    model.model_name.human(count: 2)
  end

  def query_form(&block)
    opts = {
      url: controller.url_for([:console, model]),
      method: :get,
      html: { class: 'f-c-index-header__form' },
    }

    simple_form_for('', opts, &block)
  end

  def query_autocomplete
    title_columns = model.column_names.grep(/\A(title|name)/)
    if title_columns.present?
      model.pluck(title_columns).flatten.uniq
    else
      nil
    end
  end

  def new_button(&block)
    url = controller.url_for([:console, model, action: :new])
    html_opts = { class: 'btn btn-success f-c-index-header__btn' }
    link_to(url, html_opts, &block)
  rescue NoMethodError
  end

  def csv_path
    controller.url_for([:console, model, format: :csv])
  end
end
