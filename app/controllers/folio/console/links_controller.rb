# frozen_string_literal: true

class Folio::Console::LinksController < Folio::Console::BaseController
  respond_to :json, only: [:index]

  def index
    links = Folio::Node.find_each.map do |node|
      {
        name: name(node),
        url: nested_page_path(node, add_parents: true),
      }
    end

    additional_links.each do |collection, url_proc|
      collection.find_each do |item|
        links << { name: name(item), url: url_proc.call(item) }
      end
    end

    render json: links.sort_by { |link| link[:name] }, root: false
  end

  private

    def additional_links
      []
    end

    def name(link)
      "#{link.class.model_name.human} - #{link.try(:to_label)}"
    end
end
