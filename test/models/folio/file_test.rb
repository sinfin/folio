# frozen_string_literal: true

require "test_helper"

class Folio::FileTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class CoverAtom < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
  end

  setup do
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

    def f_file.process_attached_file # hacking method to check if it is called
      # No call processing_done!
    end

    f_file.save!

    assert_not f_file.unprocessed?
    assert f_file.processing?

    # lets try default behavior (calling `processing_done!` inside `process_attached_file`)
    f_file = build(:folio_file_image)
    f_file.file = Folio::Engine.root.join("test/fixtures/folio/test.gif")

    f_file.save!

    assert_not f_file.unprocessed?
    assert_not f_file.processing?
    assert f_file.ready?

    # change of saved file (even the same source file) will trigger reprocessing
    f_file.file = Folio::Engine.root.join("test/fixtures/folio/test.gif")

    def f_file.process_attached_file # hacking method to check if it is called
      # No call processing_done!
    end

    f_file.save!

    assert_not f_file.unprocessed?
    assert f_file.processing?

    f_file.processing_done!

    assert f_file.ready?
  end

  test "saved changes not related to attached file will NOT trigger processing" do
    f_file = create(:folio_file_image, description: "test")
    assert f_file.ready?

    def f_file.process_attached_file # hacking method to check if it is called
      self.description = "This method should not be called!"
    end

    f_file.update(author: "John Snow")

    assert_equal "test", f_file.description
  end
end
