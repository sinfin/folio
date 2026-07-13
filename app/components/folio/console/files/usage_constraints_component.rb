# frozen_string_literal: true

class Folio::Console::Files::UsageConstraintsComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def can_edit?
    can_now?(:edit_usage_constraints, @file)
  end

  def allowed_sites_collection
    collection = [[I18n.t("folio.console.files.usage_constraints_component.allowed_sites_blank"), ""]]
    collection + Folio::Site.ordered.map { |site| [allowed_site_label(site), site.id] }
  end

  private
    def max_usage_count_managed_by_media_source?
      @file.max_usage_count_managed_by_media_source?
    end

    def allowed_sites_managed_by_media_source?
      @file.allowed_sites_managed_by_media_source?
    end

    def managed_by_media_source?
      max_usage_count_managed_by_media_source? || allowed_sites_managed_by_media_source?
    end

    def effective_max_usage_count
      @file.effective_attribution_max_usage_count
    end

    def managed_allowed_sites_label
      @file.allowed_sites_for_usage_constraints.map do |site|
        @file.media_source.site_label_with_max_usage_override(site)
      end.join(", ")
    end

    def can_edit_media_source?
      can_now?(:do_anything, @file.media_source)
    end

    def media_source_edit_url
      url_for([:edit, :console, @file.media_source])
    end

    def allowed_site_label(site)
      @file.media_source&.site_label_with_max_usage_override(site) || site.to_label
    end
end
