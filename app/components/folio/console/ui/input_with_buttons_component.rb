# frozen_string_literal: true

class Folio::Console::Ui::InputWithButtonsComponent < Folio::Console::ApplicationComponent
  def initialize(input:, buttons_kwargs:)
    @input = input
    @buttons_kwargs = buttons_kwargs
  end
end
