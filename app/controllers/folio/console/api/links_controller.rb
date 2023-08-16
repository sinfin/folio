# frozen_string_literal: true

class Folio::Console::Api::LinksController < Folio::Console::Api::BaseController
  def index
    links = []

    page_links.merge(additional_links).each do |klass, url_proc|
      scope = klass

      if !Rails.application.config.folio_site_is_a_singleton && klass.try(:has_belongs_to_site?)
        scope = scope.by_site(current_site)
      end

      if params[:q].present? && scope.respond_to?(:by_query)
        scope = scope.by_query(params[:q])
      end

      scope.limit(10).each do |item|
        next if item.class.try(:public?) == false
        links << {
          label: record_label(item),
          url: url_proc.call(item),
          title: item.try(:to_label)
        }
      end
    end

    if params[:q].present?
      qq = I18n.transliterate(params[:q]).downcase
    else
      qq = nil
    end

    rails_paths.each do |path, label|
      if qq.present?
        matcher = I18n.transliterate(label).downcase
        next unless matcher.include?(qq)
      end

      links << {
        label:,
        url: main_app.public_send(path),
        title: label,
      }
    end

    sorted_links = links.sort_by { |link| I18n.transliterate(link[:label]) }

    render_json(sorted_links)
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
