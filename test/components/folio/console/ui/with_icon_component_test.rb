# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::WithIconComponentTest < Folio::Console::ComponentTest
  test "show" do
    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console" do
        render_inline(Folio::Console::Ui::WithIconComponent.new)
        assert_selector(".f-c-ui-with-icon")
        assert_no_selector(".f-ui-icon")

        render_inline(Folio::Console::Ui::WithIconComponent.new("foo"))
        assert_selector(".f-c-ui-with-icon")
        assert_text("foo")
        assert_no_selector(".f-ui-icon")

        render_inline(Folio::Console::Ui::WithIconComponent.new("foo", icon: :delete))
        assert_selector(".f-c-ui-with-icon")
        assert_text("foo")
        assert_selector(".f-ui-icon")
      end
    end
  end
end
