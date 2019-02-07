# frozen_string_literal: true

class Folio::Console::Index::HeaderCell < Folio::ConsoleCell
  def title
    model.model_name.human(count: 2)
  end

  # def input
  #   text_field_tag :by_query, controller.params[:by_query],
  #                  class: 'form-control folio-console-by-query',
  #                  placeholder: t('.by_query')
  # end

  # def form(&block)
  #   opts = {
  #     method: :get,
  #     'data-auto-submit': true,
  #   }
  #   form_tag(controller.request.url, opts, &block)
  # end

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
