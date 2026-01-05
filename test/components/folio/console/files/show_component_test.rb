# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::ShowComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::ShowComponent.new(file:))

        assert_selector(".f-c-files-show")
      end
    end
  end

  def test_warning_for_returns_nil_when_file_has_no_placements
    image = create(:folio_file_image, file_placements_count: 0)
    component = Folio::Console::Files::ShowComponent.new(file: image)

    assert_nil component.warning_for(:alt)
    assert_nil component.warning_for(:description)
    assert_nil component.warning_for(:author)
  end

  def test_warning_for_alt_returns_nil_when_validation_is_disabled
    Rails.application.config.stub(:folio_files_require_alt, false) do
      image = create(:folio_file_image, alt: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:alt)
    end
  end

  def test_warning_for_alt_returns_message_when_blank_and_validation_enabled
    Rails.application.config.stub(:folio_files_require_alt, true) do
      image = create(:folio_file_image, alt: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      warning = component.warning_for(:alt)

      assert_not_nil warning
      assert_includes warning, I18n.t("errors.messages.blank")
      assert_includes warning, image.class.human_attribute_name(:alt)
    end
  end

  def test_warning_for_alt_returns_nil_when_has_value
    Rails.application.config.stub(:folio_files_require_alt, true) do
      image = create(:folio_file_image, alt: "Some alt text", file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:alt)
    end
  end

  def test_warning_for_description_returns_nil_when_validation_is_disabled
    Rails.application.config.stub(:folio_files_require_description, false) do
      image = create(:folio_file_image, description: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:description)
    end
  end

  def test_warning_for_description_returns_message_when_blank_and_validation_enabled
    Rails.application.config.stub(:folio_files_require_description, true) do
      image = create(:folio_file_image, description: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      warning = component.warning_for(:description)

      assert_not_nil warning
      assert_includes warning, I18n.t("errors.messages.blank")
      assert_includes warning, image.class.human_attribute_name(:description)
    end
  end

  def test_warning_for_description_returns_nil_when_has_value
    Rails.application.config.stub(:folio_files_require_description, true) do
      image = create(:folio_file_image, description: "Some description", file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:description)
    end
  end

  def test_warning_for_attribution_returns_nil_when_validation_is_disabled
    Rails.application.config.stub(:folio_files_require_attribution, false) do
      image = create(:folio_file_image, author: nil, attribution_source: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:author)
      assert_nil component.warning_for(:attribution_source)
    end
  end

  def test_warning_for_author_returns_message_when_all_attribution_fields_blank
    Rails.application.config.stub(:folio_files_require_attribution, true) do
      image = create(:folio_file_image, author: nil, attribution_source: nil, attribution_source_url: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)
      warning = component.warning_for(:author)

      assert_not_nil warning
      assert_includes warning, I18n.t("errors.messages.blank")
      assert_includes warning, image.class.human_attribute_name(:author)
    end
  end

  def test_warning_for_author_returns_nil_when_author_has_value
    Rails.application.config.stub(:folio_files_require_attribution, true) do
      image = create(:folio_file_image, author: "John Doe", attribution_source: nil, attribution_source_url: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:author)
    end
  end

  def test_warning_for_attribution_source_returns_message_when_all_attribution_fields_blank
    Rails.application.config.stub(:folio_files_require_attribution, true) do
      image = create(:folio_file_image, author: nil, attribution_source: nil, attribution_source_url: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      warning = component.warning_for(:attribution_source)

      assert_not_nil warning
      assert_includes warning, I18n.t("errors.messages.blank")
      assert_includes warning, image.class.human_attribute_name(:attribution_source)
    end
  end

  def test_warning_for_attribution_source_returns_nil_when_has_value
    Rails.application.config.stub(:folio_files_require_attribution, true) do
      image = create(:folio_file_image, author: nil, attribution_source: "Getty Images", attribution_source_url: nil, file_placements_count: 1)
      component = Folio::Console::Files::ShowComponent.new(file: image)

      assert_nil component.warning_for(:attribution_source)
    end
  end

  def test_warning_for_alt_does_not_show_for_non_image_files
    document = create(:folio_file_document, file_placements_count: 1)
    component = Folio::Console::Files::ShowComponent.new(file: document)

    Rails.application.config.stub(:folio_files_require_alt, true) do
      assert_nil component.warning_for(:alt)
    end
  end
end
