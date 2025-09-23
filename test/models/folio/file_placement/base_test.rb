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
        assert_equal(["nemá vyplněného autora nebo zdroj"], page.errors.messages[:"cover_placement.file"])
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
        assert_equal(["je povinná položka"], page.errors.messages[:"cover_placement.alt"])
        assert_equal(["Některé soubory nesplňují požadavky"], page.errors.messages[:base])
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
        assert_equal(["je povinná položka"], page.errors.messages[:"cover_placement.description"])
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
end
