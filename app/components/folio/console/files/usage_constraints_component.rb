# frozen_string_literal: true

class Folio::Console::Files::UsageConstraintsComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def can_edit?
    Folio::Current.ability.can?(:edit_usage_constraints, @file)
  end

  def allowed_sites_collection
    collection = [[I18n.t("folio.console.files.usage_constraints_component.allowed_sites_blank"), ""]]
    collection + Folio::Site.ordered.map { |site| [site.to_label, site.id] }
  end
end
