# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::Tabs::TabPaneComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::Tabs::TabPaneComponent.new(key: "foo")) do
      "hello"
    end

    assert_selector(".f-c-ui-tabs-tab-pane", text: "hello")
  end
end
