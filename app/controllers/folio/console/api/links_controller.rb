# frozen_string_literal: true

class Folio::Console::Api::LinksController < Folio::Console::Api::BaseController
  def index
    links = []

    page_links.merge(additional_links).each do |klass, url_proc|
      klass.find_each do |item|
        next if item.class.try(:public?) == false
        links << { name: record_label(item), url: url_proc.call(item) }
      end
    end

    rails_paths.each do |path, label|
      links << { name: label, url: main_app.public_send(path) }
    end

    sorted_links = links.sort_by { |link| I18n.transliterate(link[:name]) }

    render_json(sorted_links)
  end

  private

    def page_links
      {
        Folio::Page => Proc.new { |page| main_app.url_for([page, only_path: true]) }
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
      label = record.try(:to_console_label) || record.try(:to_label)
      "#{record.class.model_name.human} - #{label}"
    end
end
