# frozen_string_literal: true

class Folio::Console::Index::TabsCell < Folio::ConsoleCell
  include Folio::ActiveClass

  def show
    render if model.present?
  end

  def href(tab)
    query = []

    if options[:index_filters]
      (%i[by_query] + options[:index_filters].keys).each do |key|
        next if options[:params][key].blank?
        query << "#{key}=#{options[:params][key]}"
      end
    end

    if options[:params] && options[:params][:page].present?
      query << "page=#{options[:params][:page]}"
    end

    if query.present?
      "#{tab[:href]}?#{query.join('&')}"
    else
      tab[:href]
    end
  end

  def count_class_name(color = nil)
    if color
      "f-c-index-tabs__count--#{color}"
    end
  end
end
