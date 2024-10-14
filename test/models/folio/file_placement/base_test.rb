# frozen_string_literal: true

require "test_helper"

class Folio::FilePlacement::BaseTest < ActiveSupport::TestCase
  test "folio_files_require_attribution" do
    page = create(:folio_page)
    image = create(:folio_file_image, author: nil, attribution_source: nil, attribution_source_url: nil)

    I18n.with_locale(:cs) do
      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert_not page.update(cover: image)
        assert_equal "Obrázek nesplňuje požadavky. Soubor nemá vyplněného autora nebo zdroj", page.errors.full_messages.join(". ")
      end

      assert page.update(cover: image)

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert_not page.save
        assert_equal "Obrázek nesplňuje požadavky", page.errors.full_messages.join(". ")
      end
    end
  end

  test "folio_files_require_alt" do
    page = create(:folio_page)
    image = create(:folio_file_image, alt: nil)

    I18n.with_locale(:cs) do
      Rails.application.config.stub(:folio_files_require_alt, true) do
        assert_not page.update(cover: image)
        assert_equal "Obrázek nesplňuje požadavky. Soubor nemá vyplněný alt", page.errors.full_messages.join(". ")
      end

      assert page.update(cover: image)

      Rails.application.config.stub(:folio_files_require_alt, true) do
        assert_not page.save
        assert_equal "Obrázek nesplňuje požadavky", page.errors.full_messages.join(". ")
      end
    end
  end

  test "folio_files_require_description" do
    page = create(:folio_page)
    image = create(:folio_file_image, description: nil)

    I18n.with_locale(:cs) do
      Rails.application.config.stub(:folio_files_require_description, true) do
        assert_not page.update(cover: image)
        assert_equal "Obrázek nesplňuje požadavky. Soubor nemá vyplněný popisek", page.errors.full_messages.join(". ")
      end

      assert page.update(cover: image)

      Rails.application.config.stub(:folio_files_require_description, true) do
        assert_not page.save
        assert_equal "Obrázek nesplňuje požadavky", page.errors.full_messages.join(". ")
      end
    end
  end
end
