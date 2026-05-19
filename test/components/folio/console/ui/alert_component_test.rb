# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::AlertComponentTest < Folio::Console::ComponentTest
  def test_render
    "hello"

    render_inline(Folio::Console::Ui::AlertComponent.new(variant: "danger") { "foo" })

    assert_selector(".f-c-ui-alert")
  end

  def test_autohide_off_by_default
    component = Folio::Console::Ui::AlertComponent.new(variant: :loader)

    assert_equal "false", component.data["f-c-ui-alert-autohide-value"]
  end

  def test_autohide_opt_in
    component = Folio::Console::Ui::AlertComponent.new(variant: :loader, autohide: true)

    assert_equal "true", component.data["f-c-ui-alert-autohide-value"]
  end
end
