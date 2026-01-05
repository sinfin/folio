# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ValidationBoxComponentTest < Folio::Console::ComponentTest
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

  # Danger variant tests

  def test_render_danger_variant_with_errors
    page = build(:folio_page, title: nil)
    page.valid?

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/pages" do
        render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
          errors: page.errors,
          record: page
        ))
      end
    end

    assert_selector(".f-c-ui-validation-box.f-c-ui-validation-box--variant-danger")
    assert_selector("li")
  end

  def test_does_not_render_danger_variant_without_errors
    page = build(:folio_page)

    render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
      errors: [],
      record: page
    ))

    assert_no_selector(".f-c-ui-validation-box")
  end

  def test_danger_variant_shows_fix_buttons
    page = build(:folio_page, title: nil)
    page.valid?

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/pages" do
        render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
          errors: page.errors,
          record: page
        ))
      end
    end

    assert_selector(".f-c-ui-validation-box__button[hidden]", visible: :all)
  end

  # Warning variant tests

  def test_render_warning_variant_with_warnings
    file1 = create(:folio_file_image, file_name: "test1.jpg")
    file2 = create(:folio_file_image, file_name: "test2.jpg")
    page = build(:folio_page)
    warnings = [
      { file: file1, warnings: [:missing_alt, :missing_attribution] },
      { file: file2, warnings: [:missing_description] }
    ]

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
          warnings: warnings,
          record: page
        ))
      end
    end

    assert_selector(".f-c-ui-validation-box.f-c-ui-validation-box--variant-warning")
    assert_selector("li", count: 2)
    assert_text("test1.jpg")
    assert_text("test2.jpg")
  end

  def test_does_not_render_warning_variant_with_empty_warnings
    page = build(:folio_page)

    render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
      warnings: [],
      record: page
    ))

    assert_no_selector(".f-c-ui-validation-box")
  end

  def test_file_button_when_readable
    file = create(:folio_file_image, file_name: "test.jpg")
    page = build(:folio_page)
    warnings = [{ file: file, warnings: [:missing_alt] }]

    I18n.with_locale(:en) do
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
            warnings: warnings,
            record: page
          ))
        end
      end

      assert_text("test.jpg")
      assert_selector(".f-c-ui-validation-box__button", text: "Fix")
    end
  end

  def test_no_file_button_when_not_readable
    file = create(:folio_file_image, file_name: "test.jpg")
    page = build(:folio_page)
    warnings = [{ file: file, warnings: [:missing_alt] }]

    # Set user to nil to test non-readable case
    Folio::Current.user = nil

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
          warnings: warnings,
          record: page
        ))
      end
    end

    assert_text("test.jpg")
    assert_no_selector(".f-c-ui-validation-box__button")
  end

  def test_combines_warnings_with_common_prefix
    file = create(:folio_file_image, file_name: "test.jpg")
    page = build(:folio_page)
    warnings = [{ file: file, warnings: [:missing_alt, :missing_description] }]

    I18n.with_locale(:cs) do
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
            warnings: warnings,
            record: page
          ))
        end
      end

      # Should combine "nemá vyplněný alt, nemá vyplněný popisek" -> "nemá vyplněný alt a popisek"
      assert_text("nemá vyplněný alt a popisek")
      assert_no_text("nemá vyplněný alt, nemá vyplněný popisek")
    end
  end

  def test_combines_multiple_warnings_with_common_prefix
    file = create(:folio_file_image, file_name: "test.jpg")
    page = build(:folio_page)
    warnings = [{ file: file, warnings: [:missing_alt, :missing_description, :missing_attribution] }]

    I18n.with_locale(:cs) do
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Ui::ValidationBoxComponent.new(
            warnings: warnings,
            record: page
          ))
        end
      end

      # Should combine all warnings: "nemá vyplněný alt, nemá vyplněný popisek, nemá vyplněného autora nebo zdroj"
      # -> "nemá vyplněný alt, popisek a autora nebo zdroj"
      assert_text("nemá vyplněný alt, popisek a autora nebo zdroj")
      assert_no_text("nemá vyplněný alt, nemá vyplněný popisek")
    end
  end
end
