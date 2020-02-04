# frozen_string_literal: true

module Folio::Console::ShowForHelper
  def index_show_for(collection, before_lambda: nil, after_lambda: nil, &block)
    if collection.blank?
      return cell('folio/console/index/no_records', @klass).show.html_safe
    end

    empty = show_for(collection.first.class.new, &block).html_safe

    rows = [empty]

    collection.each_with_index do |item, i|
      if before_lambda
        result = before_lambda.call(item, collection, i)
        rows << result if result.present?
      end

      rows << show_for(item, &block).html_safe

      if after_lambda
        result = after_lambda.call(item, collection, i)
        rows << result if result.present?
      end
    end

    content_tag(:div, rows.join('').html_safe, class: 'f-c-show-for-index')
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
