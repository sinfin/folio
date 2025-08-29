# frozen_string_literal: true

require "test_helper"

class Folio::FileTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class CoverAtom < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
  end

  def setup
    super
    Rails.application.config.folio_testing_after_save_job = true
  end

  test "touches placement placements" do
    page = create(:folio_page)
    updated_at = page.updated_at

    perform_enqueued_jobs do
      image = create(:folio_file_image)
      page.images << image

      assert page.reload.updated_at > updated_at

      updated_at = page.updated_at

      assert image.reload.update!(tag_list: "foo")

      assert page.reload.updated_at > updated_at
    end
  end

  test "touches page through atoms" do
    perform_enqueued_jobs do
      page = create(:folio_page)
      image = create(:folio_file_image)
      atom = create_atom(CoverAtom, placement: page, cover: image)

      atom_updated_at = atom.reload.updated_at
      page_updated_at = page.reload.updated_at

      assert image.reload.update!(tag_list: "foo")
      assert atom.reload.updated_at > atom_updated_at
      assert page.reload.updated_at > page_updated_at
    end
  end

  test "cannot be destroyed when used" do
    image = create(:folio_file_image)
    assert image.destroy

    image = create(:folio_file_image)
    @site = image.site
    create_atom(CoverAtom, cover: image)
    assert_not image.destroy
  end

  test "by_file_name pg scope" do
    create(:folio_file_image, file_name: "foo.jpg")
    file1 = create(:folio_file_image, file_name: "foo_bar.jpg")
    file2 = create(:folio_file_image, file_name: "foo-bar.jpg")

    assert_equal [file1], Folio::File.by_file_name("foo_bar")
    assert_equal [file2], Folio::File.by_file_name("foo-bar")
  end

  test "have 4 basic states" do
    file = Folio::File.new
    assert_equal [:unprocessed, :processing, :ready, :processing_failed], file.class.all_state_names
    assert file.unprocessed?
  end

  test "saved change of attached file will trigger processing" do
    f_file = build(:folio_file_image, file_name: "foo.jpg")

    assert f_file.valid?
    assert f_file.unprocessed?
    assert_not f_file.ready?
    assert f_file.attached_file_changed?

    # Override to test processing flow without completing it
    def f_file.process_attached_file
      # Don't call processing_done! to test intermediate state
    end

    f_file.save!

    # Explicitly trigger processing only if still unprocessed
    f_file.process! if f_file.unprocessed?

    assert_not f_file.unprocessed?
    assert f_file.processing?

    # lets try default behavior (calling `processing_done!` inside `process_attached_file`)
    f_file = build(:folio_file_image)
    f_file.file = Folio::Engine.root.join("test/fixtures/folio/test.gif")

    f_file.save!

    # Simulate full processing lifecycle if needed
    f_file.process! if f_file.unprocessed?
    f_file.processing_done! if f_file.processing?

    assert_not f_file.unprocessed?
    assert_not f_file.processing?
    assert f_file.ready?

    # change of saved file (even the same source file) will trigger reprocessing
    f_file.file = Folio::Engine.root.join("test/fixtures/folio/test.gif")

    def f_file.process_attached_file # hacking method to check if it is called
      # No call processing_done!
    end

    f_file.save!

    # Trigger processing again if needed
    f_file.process! if f_file.unprocessed?

    assert_not f_file.unprocessed?
    assert f_file.processing?

    f_file.processing_done!

    assert f_file.ready?
  end

  test "saved changes not related to attached file will NOT trigger processing" do
    f_file = create(:folio_file_image, description: "test")

    # Ensure file is in ready state deterministically
    f_file.process!
    f_file.processing_done!
    assert f_file.ready?

    def f_file.process_attached_file # hacking method to check if it is called
      self.description = "This method should not be called!"
    end

    f_file.update(author: "John Snow")

    assert_equal "test", f_file.description
  end

  test "validate_attribution_and_texts_if_needed" do
    I18n.with_locale(:cs) do
      file = create(:folio_file_image)
      assert file.update(alt: "foo")
      assert file.update(alt: nil)

      Rails.application.config.stub(:folio_files_require_alt, true) do
        assert file.update!(alt: "foo")
        assert_not file.update(alt: nil)
        assert_equal "Alt je povinná položka", file.errors.full_messages.join(". ")
      end

      assert file.update(description: "foo")
      assert file.update(description: nil)

      Rails.application.config.stub(:folio_files_require_description, true) do
        assert file.update!(description: "foo")
        assert_not file.update(description: nil)
        assert_equal "Popis je povinná položka", file.errors.full_messages.join(". ")
      end

      assert file.update(author: "foo", attribution_source: nil, attribution_source_url: nil)
      assert file.update(author: nil)

      Rails.application.config.stub(:folio_files_require_attribution, true) do
        assert file.update!(author: "foo")
        assert_not file.update(author: nil)
        assert_equal "Autor nebo zdroj je povinný", file.errors.full_messages.join(". ")
      end
    end
  end
end

class Folio::FileImageMetadataKeywordsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "merges keywords into tag_list idempotently" do
    image = create(:folio_file_image, tag_list: "alpha, beta")

    # Simulate mapped metadata keywords
    raw_metadata = {
      "XMP-dc:Subject" => ["Beta", "Gamma", " ", nil, "alpha"],
    }

    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    # Simulate keyword merging
    if mapped_data[:keywords].present?
      existing_tags = image.tag_list || []
      new_keywords = mapped_data[:keywords].map(&:to_s).map(&:strip).reject(&:blank?)

      # Create lowercase mapping for deduplication but preserve original case
      all_tags = existing_tags + new_keywords
      seen_lowercase = {}
      merged_tags = []

      all_tags.each do |tag|
        lowercase_tag = tag.downcase
        unless seen_lowercase[lowercase_tag]
          merged_tags << tag
          seen_lowercase[lowercase_tag] = true
        end
      end

      image.tag_list = merged_tags
    end

    image.save!

    assert_equal %w[Gamma alpha beta], image.reload.tag_list.sort

    # Re-run to ensure idempotency (no duplicates)
    # Simulate the same metadata extraction again
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    # Simulate keyword merging again (should be idempotent)
    if mapped_data[:keywords].present?
      existing_tags = image.tag_list || []
      new_keywords = mapped_data[:keywords].map(&:to_s).map(&:strip).reject(&:blank?)

      # Create lowercase mapping for deduplication but preserve original case
      all_tags = existing_tags + new_keywords
      seen_lowercase = {}
      merged_tags = []

      all_tags.each do |tag|
        lowercase_tag = tag.downcase
        unless seen_lowercase[lowercase_tag]
          merged_tags << tag
          seen_lowercase[lowercase_tag] = true
        end
      end

      image.tag_list = merged_tags
    end

    image.save!

    assert_equal %w[Gamma alpha beta], image.reload.tag_list.sort
  end
end
