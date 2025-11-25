# frozen_string_literal: true

require "test_helper"

class Folio::Console::Form::WarningsComponentTest < Folio::Console::ComponentTest
  def setup
    super
    @superadmin = create(:folio_user, :superadmin)
    Folio::Current.user = @superadmin
    Folio::Current.reset_ability!
  end

  def teardown
    Folio::Current.user = nil
    super
  end

  def test_render_with_warnings
    file1 = create(:folio_file_image, file_name: "test1.jpg")
    file2 = create(:folio_file_image, file_name: "test2.jpg")
    warnings = [
      { file: file1, warnings: [:missing_alt, :missing_attribution] },
      { file: file2, warnings: [:missing_description] }
    ]

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings, record_key: "test-key"))
      end
    end

    assert_selector(".f-c-form-warnings")
    assert_selector("li", count: 2)
    assert_text("test1.jpg")
    assert_text("test2.jpg")
  end

  def test_render_with_empty_warnings
    render_inline(Folio::Console::Form::WarningsComponent.new(warnings: []))

    assert_no_selector(".f-c-form-warnings")
  end

  def test_file_link_when_readable
    file = create(:folio_file_image, file_name: "test.jpg")
    warnings = [{ file: file, warnings: [:missing_alt] }]

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))
      end
    end

    assert_selector("span.fw-bold.f-c-form-warnings__file-trigger")
    assert_text("test.jpg")
  end

  def test_file_name_plain_text_when_not_readable
    file = create(:folio_file_image, file_name: "test.jpg")
    warnings = [{ file: file, warnings: [:missing_alt] }]

    # Set user to nil to test non-readable case
    Folio::Current.user = nil

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))
      end
    end

    assert_selector("span.fw-bold")
    assert_no_selector(".f-c-form-warnings__file-trigger")
    assert_text("test.jpg")
  end

  def test_combines_warnings_with_common_prefix
    file = create(:folio_file_image, file_name: "test.jpg")
    warnings = [{ file: file, warnings: [:missing_alt, :missing_description] }]

    I18n.with_locale(:cs) do
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))
        end
      end

      # Should combine "nemá vyplněný alt, nemá vyplněný popisek" -> "nemá vyplněný alt a popisek"
      assert_text("nemá vyplněný alt a popisek")
      assert_no_text("nemá vyplněný alt, nemá vyplněný popisek")
    end
  end

  def test_combines_multiple_warnings_with_common_prefix
    file = create(:folio_file_image, file_name: "test.jpg")
    warnings = [{ file: file, warnings: [:missing_alt, :missing_description, :missing_attribution] }]

    I18n.with_locale(:cs) do
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Form::WarningsComponent.new(warnings: warnings))
        end
      end

      # Should combine all warnings: "nemá vyplněný alt, nemá vyplněný popisek, nemá vyplněného autora nebo zdroj"
      # -> "nemá vyplněný alt, popisek a autora nebo zdroj"
      assert_text("nemá vyplněný alt, popisek a autora nebo zdroj")
      assert_no_text("nemá vyplněný alt, nemá vyplněný popisek")
    end
  end
end
