# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    render_inline(Dummy::Ui::HeaderComponent.new)

    assert_selector(".d-ui-header")
  end
end
