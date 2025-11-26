# frozen_string_literal: true

require "test_helper"

class Folio::Console::Form::WarningsComponentTest < Folio::Console::ComponentTest
  def test_render_with_warnings
    warnings = ["Warning 1", "Warning 2", "Warning 3"]

    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings, record_key: "test-key"))

    assert_selector(".f-c-form-warnings")
    assert_selector(".f-c-form-warnings.alert.alert-warning.d-none")
    assert_selector("li", count: 3)
    assert_text("Warning 1")
    assert_text("Warning 2")
    assert_text("Warning 3")
  end

  def test_render_with_empty_warnings
    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: []))

    assert_selector(".f-c-form-warnings")
    assert_selector("li", count: 0)
  end

  def test_render_with_notification
    warnings = ["Warning 1"]

    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))

    assert_selector(".fw-bold.mb-2")
    assert_text(I18n.t("folio.console.form.warnings_component.notification"))
  end

  def test_render_with_record_key
    warnings = ["Warning 1"]

    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings, record_key: "articles-123"))

    assert_selector(".f-c-form-warnings[data-f-c-form-warnings-record-key-value='articles-123']")
  end

  def test_render_without_record_key
    warnings = ["Warning 1"]

    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))

    assert_selector(".f-c-form-warnings")
  end

  def test_stimulus_controller_data
    warnings = ["Warning 1"]

    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings, record_key: "test-123"))

    assert_selector(".f-c-form-warnings[data-controller='f-c-form-warnings']")
    assert_selector("[data-action*='submit@document->f-c-form-warnings#show']")
  end

  def test_warning_items_structure
    warnings = ["First warning", "Second warning"]

    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))

    assert_selector("ul")
    assert_selector("li.d-flex.align-items-center", count: 2)
    assert_selector("li:first-child:not(.mt-2)")
    assert_selector("li:nth-child(2).mt-2")
  end
end
