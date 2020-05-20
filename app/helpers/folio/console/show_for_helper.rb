# frozen_string_literal: true

module Folio::Console::ShowForHelper
  def index_show_for(model, before_lambda: nil, after_lambda: nil, group_by_day: nil, group_by_day_label_before: nil, group_by_day_label_lambda: nil, &block)
    if group_by_day && !before_lambda
      before_lambda = -> (record, collection, i) do
        date = record.send(group_by_day)
        day = date.try(:beginning_of_day)

        return if day.blank?

        if i > 0
          prev_day = collection[i - 1].send(group_by_day).try(:beginning_of_day)
        else
          prev_day = nil
        end

        return if day == prev_day

        cell('folio/console/group_by_day_header',
             scope: model,
             date: date,
             attribute: group_by_day,
             before_label: group_by_day_label_before,
             label_lambda: group_by_day_label_lambda).show.try(:html_safe)
      end
    end

    render partial: 'folio/console/partials/index_show_for',
           locals: {
             model: model,
             before_lambda: before_lambda,
             after_lambda: after_lambda,
             klass: @klass,
             block: block,
             folio_console_merge: @folio_console_merge,
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
