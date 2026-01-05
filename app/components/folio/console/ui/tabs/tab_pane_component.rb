# frozen_string_literal: true

class Folio::Console::Ui::Tabs::TabPaneComponent < Folio::Console::ApplicationComponent
  def initialize(key:, active: false)
    @key = key
    @active = active
  end

  private
    def data
      stimulus_controller("f-c-ui-tabs-tab-pane",
                          action: {
                            "f-c-ui-tabs:show" => "onShow",
                            "f-c-ui-tabs:shown" => "onShown",
                            "f-c-ui-tabs:hide" => "onHide",
                            "f-c-ui-tabs:hidden" => "onHidden",
                          })
    end
end
