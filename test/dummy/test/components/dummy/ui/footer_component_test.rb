# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::FooterComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    render_inline(Dummy::Ui::FooterComponent.new)

    assert_selector(".d-ui-footer")
  end
end
