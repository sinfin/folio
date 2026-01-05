# frozen_string_literal: true

class Folio::Console::Ui::BadgeComponent < Folio::Console::ApplicationComponent
  def initialize(variant: :secondary, icon: nil, size: nil)
    @variant = variant
    @icon = icon
    @size = size
  end
end
