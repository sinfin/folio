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
    def allowed_site_label(site)
      max_usage_count = @file.media_source&.rule_for_site(site)&.max_usage_count

      if max_usage_count.present?
        "#{site.to_label} (#{max_usage_count})"
      else
        site.to_label
      end
    end
end
