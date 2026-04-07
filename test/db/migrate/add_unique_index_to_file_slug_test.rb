# frozen_string_literal: true

require "test_helper"
require_relative "../../../db/migrate/20260331165642_add_unique_index_to_file_slug"

class AddUniqueIndexToFileSlugTest < ActiveSupport::TestCase
  # DDL operations (index swap) cannot run inside a transaction
  self.use_transactional_tests = false

  NEW_INDEX = "index_folio_files_on_slug_unique"
  OLD_INDEX = "index_folio_files_on_slug"

  setup do
    @pre_existing_site_ids = Folio::Site.pluck(:id)
    @files_to_cleanup = []
    swap_to_non_unique_index
  end

  teardown do
    Folio::File.where(id: @files_to_cleanup.map(&:id)).destroy_all
    Folio::Site.where.not(id: @pre_existing_site_ids).destroy_all
    swap_to_unique_index
  end

  test "backfills null slugs with neutral timestamp-hex format" do
    file = track(create(:folio_file_image, media_source: nil))
    file.update_column(:slug, nil)

    run_data_steps

    assert_match(/\A\d{10}-[0-9a-f]{10}\z/, file.reload.slug)
  end

  test "keeps oldest file slug when deduplicating" do
    older, newer = create_duplicate_pair
    original_slug = older.slug

    run_data_steps

    assert_equal original_slug, older.reload.slug
    assert_not_equal original_slug, newer.reload.slug
  end

  test "renamed file gets a unique valid slug" do
    older, newer = create_duplicate_pair

    run_data_steps

    newer.reload
    assert_match(/\A[0-9a-z-]+\z/, newer.slug)
    assert_equal 1, Folio::File.where(slug: newer.slug).count
  end

  test "creates friendly_id history entry for renamed file's new slug" do
    _older, newer = create_duplicate_pair

    run_data_steps

    newer.reload
    assert FriendlyId::Slug.exists?(sluggable: newer, slug: newer.slug),
           "Expected friendly_id history entry for renamed file's new slug #{newer.slug}"
  end

  test "renamed file is findable via its new slug" do
    older, newer = create_duplicate_pair
    original_slug = older.slug

    run_data_steps

    newer.reload
    found = Folio::File.friendly.find(newer.slug)
    assert_equal newer.id, found.id

    assert_equal older.id, Folio::File.friendly.find(original_slug).id
  end

  test "handles three-way duplicates correctly" do
    base = track(create(:folio_file_image, media_source: nil))
    mid  = track(create(:folio_file_image, media_source: nil, created_at: base.created_at + 1.second))
    late = track(create(:folio_file_image, media_source: nil, created_at: base.created_at + 2.seconds))

    mid.update_column(:slug, base.slug)
    late.update_column(:slug, base.slug)

    run_data_steps

    slugs = [base, mid, late].map { |f| f.reload.slug }
    assert_equal slugs.uniq.size, 3, "All three files should have different slugs"
    assert_equal base.slug, slugs.first, "Oldest file should keep the original slug"
  end

  private

    def track(file)
      @files_to_cleanup << file
      file
    end

    def create_duplicate_pair
      older = track(create(:folio_file_image, media_source: nil))
      newer = track(create(:folio_file_image, media_source: nil))
      newer.update_column(:created_at, older.created_at + 1.second)
      newer.update_column(:slug, older.slug)
      [older, newer]
    end

    def run_data_steps
      m = AddUniqueIndexToFileSlug.new
      m.send(:backfill_null_slugs)
      m.send(:deduplicate_slugs)
    end

    def swap_to_non_unique_index
      conn = ActiveRecord::Base.connection
      return unless conn.indexes(:folio_files).any? { |i| i.name == NEW_INDEX }

      conn.remove_index :folio_files, name: NEW_INDEX
      conn.add_index :folio_files, :slug, name: OLD_INDEX
    end

    def swap_to_unique_index
      conn = ActiveRecord::Base.connection
      return if conn.indexes(:folio_files).any? { |i| i.name == NEW_INDEX }

      conn.remove_index :folio_files, name: OLD_INDEX if conn.indexes(:folio_files).any? { |i| i.name == OLD_INDEX }
      conn.add_index :folio_files, :slug, unique: true, name: NEW_INDEX
    end
end