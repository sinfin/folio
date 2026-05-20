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

  def test_extra_stimulus_controllers_are_appended
    component = Folio::Console::Ui::AlertComponent.new(variant: :info, stimulus_controllers: ["x-progress", "x-other"])

    assert_equal "f-c-ui-alert x-progress x-other", component.data["controller"]
  end

  def test_extra_data_is_merged_onto_root
    component = Folio::Console::Ui::AlertComponent.new(variant: :info,
                                                       data: { "x-progress-session-id-value" => "abc",
                                                               "x-progress-expected-value" => 3 })

    assert_equal "abc", component.data["x-progress-session-id-value"]
    assert_equal 3, component.data["x-progress-expected-value"]
    assert_equal "f-c-ui-alert", component.data["controller"]
  end

  def test_extra_data_does_not_clobber_existing_autohide
    component = Folio::Console::Ui::AlertComponent.new(variant: :info,
                                                       autohide: true,
                                                       data: { "x-progress-session-id-value" => "abc" })

    assert_equal "true", component.data["f-c-ui-alert-autohide-value"]
    assert_equal "abc", component.data["x-progress-session-id-value"]
  end
end
