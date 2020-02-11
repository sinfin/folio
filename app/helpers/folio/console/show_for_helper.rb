# frozen_string_literal: true

module Folio::Console::ShowForHelper
  def index_show_for(model, before_lambda: nil, after_lambda: nil, &block)
    render partial: 'folio/console/partials/index_show_for',
           locals: {
             model: model,
             before_lambda: before_lambda,
             after_lambda: after_lambda,
             klass: @klass,
             block: block,
           }
  end

  def table_show_for(model, wide: false, &block)
    if wide
      class_name = 'f-c-show-for-table f-c-show-for-table--wide'
    else
      class_name = 'f-c-show-for-table'
    end

    content_tag(:div, show_for(model, &block), class: class_name)
  end

  def small_show_for(model, &block)
    content_tag(:div, show_for(model, &block), class: 'f-c-show-for-small')
  end
end
