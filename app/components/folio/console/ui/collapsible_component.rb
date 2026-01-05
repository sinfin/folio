# frozen_string_literal: true

class Folio::Console::Ui::CollapsibleComponent < Folio::Console::ApplicationComponent
  FOCUS_INPUT_CLASS_NAME = "f-c-ui-collapsible-focus-input"

  def initialize(title:, collapsed: true)
    @title = title
    @collapsed = collapsed
  end

  private
    def data
      stimulus_controller("f-c-ui-collapsible",
                          values: {
                            collapsed: @collapsed,
                          })
    end
end
