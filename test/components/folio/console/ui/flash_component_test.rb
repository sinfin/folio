# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::FlashComponentTest < Folio::Console::ComponentTest
  def test_render
    flash = ActionDispatch::Flash::FlashHash.new
    flash[:error] = "foo"

    render_inline(Folio::Console::Ui::FlashComponent.new(flash:))

    assert_selector(".f-c-ui-flash")
    assert_selector(".f-c-ui-flash .f-c-ui-alert")
  end

  def test_blank
    flash = nil

    render_inline(Folio::Console::Ui::FlashComponent.new(flash:))

    assert_selector(".f-c-ui-flash", visible: false)
    assert_no_selector(".f-c-ui-flash .f-c-ui-alert")
  end

  def test_autohide_propagates_from_flash
    component = Folio::Console::Ui::FlashComponent.new(flash: { "notice" => "foo", "autohide" => true })

    assert_equal true, component.autohide
    assert_equal({ "notice" => "foo" }, component.instance_variable_get(:@flash))
  end

  def test_autohide_off_when_not_set
    component = Folio::Console::Ui::FlashComponent.new(flash: { "notice" => "foo" })

    assert_equal false, component.autohide
  end

  def test_alert_stimulus_controllers_extracted_from_flash
    component = Folio::Console::Ui::FlashComponent.new(flash: { "notice" => "foo",
                                                                "alert_stimulus_controllers" => ["x-progress"],
                                                                "alert_data" => { "x-progress-session-id-value" => "abc" } })

    assert_equal ["x-progress"], component.alert_stimulus_controllers
    assert_equal({ "x-progress-session-id-value" => "abc" }, component.alert_data)
    assert_equal({ "notice" => "foo" }, component.instance_variable_get(:@flash))
  end

  def test_alert_stimulus_controllers_default_empty
    component = Folio::Console::Ui::FlashComponent.new(flash: { "notice" => "foo" })

    assert_equal [], component.alert_stimulus_controllers
    assert_equal({}, component.alert_data)
  end
end
