# frozen_string_literal: true

class Folio::Console::Form::LayoutComponent < Folio::Console::ApplicationComponent
  renders_one :header
  renders_one :file_pickers

  def initialize; end
end
