# frozen_string_literal: true

class Folio::Console::LinksController < Folio::Console::BaseController
  respond_to :json, only: [:index]

  def index
    links = []

    node_links.merge(additional_links).each do |klass, url_proc|
      klass.find_each do |item|
        links << { name: record_label(item), url: url_proc.call(item) }
      end
    end

    render json: links.sort_by { |link| link[:name] }, root: false
  end

  private

    def node_links
      {
        Folio::Node => Proc.new { |node| nested_page_path(node, add_parents: true) }
      }
    end

    def additional_links
      # {
      #   Klass => Proc.new { |instance| main_app.klass_path(instance) },
      # }
      {}
    end

    def record_label(record)
      "#{record.class.model_name.human} - #{record.try(:to_label)}"
    end
end
