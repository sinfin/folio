# frozen_string_literal: true

require "test_helper"

class Folio::FileTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class CoverAtom < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
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
end
