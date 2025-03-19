# frozen_string_literal: true

class Folio::Console::Files::ShowComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end
end
