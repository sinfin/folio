# frozen_string_literal: true

class Folio::Console::Atoms::WordCountComponent < Folio::Console::ApplicationComponent
  def initialize(locale: nil)
    @locale = locale
  end

  def data
    stimulus_controller("f-c-atoms-word-count",
                        values: {
                          locale: @locale || "",
                        },
                        action: {
                          "updateAtomPreviews@window" => "onUpdateAtomPreviews"
                        })
  end
end
