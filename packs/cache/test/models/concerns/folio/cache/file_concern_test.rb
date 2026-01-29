# frozen_string_literal: true

require "test_helper"

class Folio::Cache::FileConcernTest < ActiveSupport::TestCase
  test "updating image placed on page invalidates folio_pages cache" do
    site = create_site
    page = create(:folio_page, site:)
    image = create(:folio_file_image, site:)
    create(:folio_file_placement_image, file: image, placement: page)
    image.reload

    v_pages = Folio::Cache::Version.find_or_create_by!(site:, key: Folio::Cache::CACHE_KEYS[:pages])
    v_files = Folio::Cache::Version.find_or_create_by!(site:, key: Folio::Cache::CACHE_KEYS[:files])
    v_other = Folio::Cache::Version.find_or_create_by!(site:, key: "other")

    original_pages_updated_at = v_pages.updated_at
    original_files_updated_at = v_files.updated_at
    original_other_updated_at = v_other.updated_at

    travel 1.second do
      # Update the image - this saves it, triggering cache invalidation
      image.update!(alt: "Updated alt text")
    end

    # Both folio_pages and folio_files should be invalidated
    assert v_pages.reload.updated_at > original_pages_updated_at, "folio_pages cache should be invalidated"
    assert v_files.reload.updated_at > original_files_updated_at, "folio_files cache should be invalidated"
    assert_equal original_other_updated_at, v_other.reload.updated_at, "other cache should not be invalidated"
  end
end
