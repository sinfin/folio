# frozen_string_literal: true

class Folio::Console::Files::Show::FilePlacementsComponent < Folio::Console::ApplicationComponent
  include Pagy::Backend
  include Pagy::Frontend

  def initialize(file:)
    @file = file
  end

  private
    def before_render
      @pagy, @file_placements = pagy(@file.file_placements.includes(:placement).order(created_at: :desc), items: 20)
    end

    def placement_label(placement)
      placement.try(:to_label) || "##{placement.id}"
    end

    def placement_record(file_placement)
      if file_placement.placement.is_a?(Folio::Atom::Base) && file_placement.placement.placement.present?
        file_placement.placement.placement
      else
        file_placement.placement
      end
    end

    def placement_site_label(placement)
      return "-" unless placement.respond_to?(:site)

      placement.site&.to_label || "-"
    end

    def show_site_column?
      Rails.application.config.folio_shared_files_between_sites
    end

    def placement_action(placement)
      if can_now?(:update, placement)
        return { type: :edit, url: placement_url(placement, action: :edit) }
      elsif can_now?(:read, placement)
        return { type: :show, url: placement_url(placement, action: :show) }
      end

      { type: :none }
    rescue StandardError
      { type: :none }
    end

    def placement_url(placement, action: :show)
      if placement.class.try(:has_belongs_to_site?) && placement.site
        url_for([:console, placement, action:, host: placement.site.env_aware_domain, only_path: false])
      else
        url_for([:console, placement, action:])
      end
    end
end
