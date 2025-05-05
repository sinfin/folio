# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::DisclaimerComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    render_inline(Dummy::Ui::DisclaimerComponent.new)

    assert_selector(".d-ui-disclaimer")
  end
end
