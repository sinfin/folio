# frozen_string_literal: true

module Folio::Console::ShowForHelper
  def index_show_for(collection, &block)
    if collection.blank?
      return cell('folio/console/index/no_records', @klass).show.html_safe
    end

    empty = show_for(collection.first.class.new, &block).html_safe

    all = [empty] + collection.map do |item|
      show_for(item, &block).html_safe
    end
    content_tag(:div, all.join('').html_safe, class: 'f-c-show-for-index')
  end

  def table_show_for(model, wide: false, &block)
    if wide
      class_name = 'f-c-show-for-table f-c-show-for-table--wide'
    else
      class_name = 'f-c-show-for-table'
    end

    content_tag(:div, show_for(model, &block), class: class_name)
  end
end
