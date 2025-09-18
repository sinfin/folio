# frozen_string_literal: true

class Folio::Console::Files::UsageConstraintsComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def can_edit?
    Folio::Current.ability.can?(:edit_usage_constraints, @file)
  end
end
