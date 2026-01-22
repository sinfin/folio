# frozen_string_literal: true

class Folio::Console::Ui::WarningRibbonComponent < Folio::Console::ApplicationComponent
  def initialize(text:, class_name: nil)
    @text = text
    @class_name = class_name
  end
end
