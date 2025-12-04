# frozen_string_literal: true

require "test_helper"

class Folio::FilePlacement::BaseTest < ActiveSupport::TestCase
  test "folio_files_require_attribution" do
    page = create(:folio_page)
    image = create(:folio_file_image,
                   author: nil,
                   attribution_source: nil,
                   attribution_source_url: nil)

    I18n.with_locale(:cs) do
      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert_not page.update(cover: image)
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
        assert_equal(["\"#{image.file_name}\" (##{image.id}) využitý pro \"Obrázek\" nemá vyplněného autora nebo zdroj"], page.errors.messages[:"cover_placement.file"])
      end

      assert page.update(cover: image)

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert_not page.save
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
      end

      Rails.application.config.stub(:folio_files_require_attribution, false) do
        image.update(author: "foo")
      end

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert page.save
      end

      Rails.application.config.stub(:folio_files_require_attribution, false) do
        image.update(author: nil)
      end

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert_not page.save
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
      end

      Rails.application.config.stub(:folio_files_require_attribution, false) do
        image.update(attribution_source: "foo", description: "foo")
      end

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert page.save
      end

      Rails.application.config.stub(:folio_files_require_attribution, false) do
        image.update!(description: nil)
        page.cover_placement.update!(description: "bar")
      end

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert page.save
      end
    end
  end

  test "folio_files_require_alt" do
    page = create(:folio_page)
    image = create(:folio_file_image, alt: nil)

    I18n.with_locale(:cs) do
      Rails.application.config.stub(:folio_files_require_alt, true) do
        assert_not page.update(cover: image)
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
        assert_equal(["pro \"#{image.file_name}\" (##{image.id}) je pro \"Obrázek\" povinný"], page.errors.messages[:"cover_placement.alt"])
      end

      Rails.application.config.stub(:folio_files_require_alt, false) do
        assert page.update(cover: image)
      end

      Rails.application.config.stub(:folio_files_require_alt, true) do
        assert_not page.save
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
      end
    end
  end

  test "folio_files_require_description" do
    page = create(:folio_page)
    image = create(:folio_file_image, description: nil)

    I18n.with_locale(:cs) do
      Rails.application.config.stub(:folio_files_require_description, true) do
        assert_not page.update(cover: image)
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
        assert_equal(["pro \"#{image.file_name}\" (##{image.id}) je pro \"Obrázek\" povinný"], page.errors.messages[:"cover_placement.description"])
      end

      Rails.application.config.stub(:folio_files_require_description, false) do
        assert page.update(cover: image)
      end

      Rails.application.config.stub(:folio_files_require_description, true) do
        assert_not page.save
        assert_equal(["nesplňuje požadavky"], page.errors.messages[:cover_placement])
      end
    end
  end

  test "console_warnings returns empty array when no file" do
    placement = Folio::FilePlacement::Cover.new

    assert_equal [], placement.console_warnings
  end

  test "console_warnings returns warning for missing alt" do
    image = create(:folio_file_image, alt: nil)
    page = create(:folio_page)
    placement = page.create_cover_placement(file: image)

    Rails.application.config.stub(:folio_files_require_alt, true) do
      warnings = placement.console_warnings

      assert_equal 1, warnings.length
      assert_includes warnings, :missing_alt
    end
  end

  test "console_warnings returns warning for missing description" do
    image = create(:folio_file_image, description: nil, alt: "test")
    page = create(:folio_page)
    placement = page.create_cover_placement(file: image)

    Rails.application.config.stub(:folio_files_require_description, true) do
      warnings = placement.console_warnings

      assert_equal 1, warnings.length
      assert_includes warnings, :missing_description
    end
  end

  test "console_warnings returns warning for missing attribution" do
    image = create(:folio_file_image,
                   author: nil,
                   attribution_source: nil,
                   attribution_source_url: nil,
                   alt: "test",
                   description: "test")
    page = create(:folio_page)
    placement = page.create_cover_placement(file: image)

    Rails.application.config.stub(:folio_files_require_attribution, true) do
      warnings = placement.console_warnings

      assert_equal 1, warnings.length
      assert_includes warnings, :missing_attribution
    end
  end

  test "console_warnings returns multiple warnings" do
    image = create(:folio_file_image,
                   alt: nil,
                   description: nil,
                   author: nil,
                   attribution_source: nil,
                   attribution_source_url: nil)
    page = create(:folio_page)
    placement = page.create_cover_placement(file: image)

    Rails.application.config.stub(:folio_files_require_alt, true) do
      Rails.application.config.stub(:folio_files_require_description, true) do
        Rails.application.config.stub(:folio_files_require_attribution, true) do
          warnings = placement.console_warnings

          assert_equal 3, warnings.length
          assert_includes warnings, :missing_alt
          assert_includes warnings, :missing_description
          assert_includes warnings, :missing_attribution
        end
      end
    end
  end

  test "console_warnings returns empty array when all fields are filled" do
    image = create(:folio_file_image,
                   alt: "test alt",
                   description: "test description",
                   author: "test author")
    page = create(:folio_page)
    placement = page.create_cover_placement(file: image)

    warnings = placement.console_warnings

    assert_equal [], warnings
  end
end
