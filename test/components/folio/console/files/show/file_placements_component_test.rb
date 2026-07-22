# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::FilePlacementsComponentTest < Folio::Console::ComponentTest
  def test_render_no_placements
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file:))

    assert_selector(".f-c-files-show-file-placements")
    assert_no_selector(".f-c-files-show-file-placements__table")
  end

  def test_render_with_placements
    file = create(:folio_file_placement_cover).file

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file:))

    assert_selector(".f-c-files-show-file-placements")
    assert_selector(".f-c-files-show-file-placements__table")
  end

  def test_render_with_placement_site
    with_config(folio_shared_files_between_sites: true) do
      site = create(:dummy_site, title: "Site title")
      article = create(:dummy_blog_article, site:)
      file = create(:folio_file_image, site:)

      article.image_placements.create!(file:)

      render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file:))

      assert_selector(".f-c-files-show-file-placements__table")
      assert_text "Site title"
    end
  end

  def test_render_without_placement_site_when_files_are_not_shared
    with_config(folio_shared_files_between_sites: false) do
      site = create(:dummy_site, title: "Site title")
      article = create(:dummy_blog_article, site:)
      file = create(:folio_file_image, site:)

      article.image_placements.create!(file:)

      render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file:))

      assert_selector(".f-c-files-show-file-placements__table")
      assert_no_text "Site title"
    end
  end
end
