# frozen_string_literal: true

class Folio::Console::Atoms::Previews::ErrorComponent < Folio::Console::ApplicationComponent
  def initialize; end

  def data
    stimulus_controller("f-c-atoms-previews-error",
                        values: { timer: 3, error: "" })
  end
end
