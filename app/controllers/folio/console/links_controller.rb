# frozen_string_literal: true

class Folio::Console::LinksController < Folio::Console::BaseController
  respond_to :json, only: [:index]

  def index
    links = []

    page_links.merge(additional_links).each do |klass, url_proc|
      klass.find_each do |item|
        links << { name: record_label(item), url: url_proc.call(item) }
      end
    end

    rails_paths.each do |path, label|
      links << { name: label, url: main_app.public_send(path) }
    end

    sorted_links = links.sort_by { |link| I18n.transliterate(link[:name]) }

    render json: sorted_links, root: false
  end

  private

    def page_links
      {
        Folio::Page => Proc.new { |page| nested_page_path(page, add_parents: true) }
      }
    end

    def additional_links
      # {
      #   Klass => Proc.new { |instance| main_app.klass_path(instance) },
      # }
      {}
    end

    def rails_paths
      # {
      #   :path_symbol => "label",
      # }
      {}
    end

    def record_label(record)
      "#{record.class.model_name.human} - #{record.try(:to_label)}"
    end
end
