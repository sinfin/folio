# frozen_string_literal: true

require "test_helper"

class Folio::Console::HtmlAutoFormat::ToggleComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        render_inline(Folio::Console::HtmlAutoFormat::ToggleComponent.new)

        assert_selector(".f-c-html-auto-format-toggle")
      end
    end
  end
end
