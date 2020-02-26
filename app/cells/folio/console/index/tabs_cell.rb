# frozen_string_literal: true

class Folio::Console::Index::TabsCell < Folio::ConsoleCell
  include Folio::ActiveClass

  def show
    render if model.present?
  end

  def href(tab)
    if options[:index_filters]
      query = []
      (%i[by_query] + options[:index_filters].keys).each do |key|
        next if options[:params][key].blank?
        query << "#{key}=#{options[:params][key]}"
      end

      if query.present?
        return "#{tab[:href]}?#{query.join('&')}"
      end
    end

    tab[:href]
  end
end
