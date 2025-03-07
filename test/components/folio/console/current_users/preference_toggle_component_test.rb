# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsers::PreferenceToggleComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        render_inline(Folio::Console::CurrentUsers::PreferenceToggleComponent.new(key: "key",
                                                                                  javascript_key: "key",
                                                                                  label: "label"))

        assert_selector(".f-c-current-users-preference-toggle")
      end
    end
  end
end
