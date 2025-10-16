# frozen_string_literal: true

class Folio::Console::Ui::ClearButtonComponent < Folio::Console::ApplicationComponent
  def initialize; end

  def data
    stimulus_controller("f-c-ui-clear-button")
  end
end
