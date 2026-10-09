# frozen_string_literal: true

class Folio::Console::Ui::ButtonsComponent < Folio::Console::ApplicationComponent
  bem_class_name :nowrap, :vertical, :centered

  def initialize(buttons:, class_name: nil, nowrap: false, vertical: false, centered: false)
    @buttons = buttons
    @class_name = class_name
    @nowrap = nowrap
    @vertical = vertical
    @centered = centered
  end
end
