# frozen_string_literal: true

class Folio::Console::Index::TabsCell < Folio::ConsoleCell
  def show
    render if model.present?
  end

  def href(tab)
    return tab[:force_href] if tab[:force_href]

    query = {}

    if options[:index_filters_keys]
      (%i[by_query] + options[:index_filters_keys]).each do |key|
        next if options[:params][key].blank?
        query[key] = options[:params][key]
      end
    end

    if options[:params] && options[:params][:page].present?
      query[:page] = options[:params][:page]
    end

    if query.present?
      joiner = tab[:href].include?("?") ? "&" : "?"
      "#{tab[:href]}#{joiner}#{query.to_query}"
    else
      tab[:href]
    end
  end

  def tabs
    model.map do |tab|
      tab.merge(href: href(tab))
    end
  end
end
