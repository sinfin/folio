# frozen_string_literal: true

class Folio::Console::Ui::WarningRibbonComponent < Folio::Console::ApplicationComponent
  def initialize(message:, class_name: nil)
    @message = message
    @class_name = class_name
  end
end
