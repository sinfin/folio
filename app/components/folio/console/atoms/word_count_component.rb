# frozen_string_literal: true

class Folio::Console::Atoms::WordCountComponent < Folio::Console::ApplicationComponent
  def initialize(locale: nil, visible: true)
    @locale = locale
    @visible = visible
  end

  def data
    stimulus_controller("f-c-atoms-word-count",
                        values: {
                          locale: @locale || "",
                          visible: @visible,
                        },
                        action: {
                          "updateAtomPreviews@window" => "onUpdateAtomPreviews",
                          "atomsLocaleSwitch@window" => "onAtomsLocaleSwitch"
                        })
  end
end
