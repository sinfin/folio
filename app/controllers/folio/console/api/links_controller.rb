# frozen_string_literal: true

class Folio::Console::Api::LinksController < Folio::Console::Api::BaseController
  def index
    links = []

    page_links.merge(additional_links).each do |klass, url_proc|
      scope = klass

      if params[:q].present? && scope.respond_to?(:by_query)
        scope = scope.by_query(params[:q])
      end

      scope.limit(10).each do |item|
        next if item.class.try(:public?) == false
        links << {
          text: record_label(item),
          id: url_proc.call(item),
          "data-title" => item.try(:to_label)
        }
      end
    end

    rails_paths.each do |path, label|
      next if params[:q].present? && !label.include?(params[:q])
      links << {
        text: label,
        id: main_app.public_send(path),
        title: label,
      }
    end

    sorted_links = links.sort_by { |link| I18n.transliterate(link[:text]) }

    render json: { results: sorted_links }
  end

  private
    def page_links
      if Rails.application.config.folio_pages_ancestry
        {
          Folio::Page => Proc.new { |page| main_app.page_path(page.to_preview_param) }
        }
      else
        {
          Folio::Page => Proc.new { |page| main_app.url_for(page) }
        }
      end
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
