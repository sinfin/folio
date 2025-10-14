# frozen_string_literal: true

class Folio::Console::Ui::ClearButtonComponent < Folio::Console::ApplicationComponent
  def initialize(model: nil)
    @model = model
  end
end
