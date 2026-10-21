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

    def rows
      @file_placements.map do |file_placement|
        owner = placement_record(file_placement)

        {
          file_placement:,
          owner:,
          orphaned: owner.nil?,
          published: owner_published(owner),
          action: owner ? placement_action(owner) : { type: :none },
        }
      end
    end

    # true / false / nil (nil = owner has no published concept or is orphaned)
    def owner_published(owner)
      return nil if owner.nil? || !owner.respond_to?(:published?)
      owner.published?
    end

    def orphaned_label(file_placement)
      file_placement.placement_title.presence || "##{file_placement.id}"
    end

    def orphaned_type(file_placement)
      file_placement.placement_title_type.presence&.safe_constantize&.model_name&.human ||
        file_placement.type.safe_constantize&.model_name&.human ||
        file_placement.type
    end

    def placement_label(placement)
      placement.try(:to_label) || "##{placement.id}"
    end

    def placement_record(file_placement)
      owner = file_placement.placement
      owner.is_a?(Folio::Atom::Base) ? owner.placement : owner
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
