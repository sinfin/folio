# frozen_string_literal: true

require "test_helper"

class Folio::FilePlacementTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class MyAtom < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
  end

  def setup
    super
    Rails.application.config.folio_testing_after_save_job = true
  end

  test "placement_title" do
    perform_enqueued_jobs do
      I18n.with_locale(:cs) do
        page = create(:folio_page, title: "foo")
        page.cover = create(:folio_file_image)

        # works
        assert_equal("Stránka - foo", page.cover_placement.reload.placement_title)
        assert_equal("Folio::Page", page.cover_placement.placement_title_type)

        # updates through touch
        page.update!(title: "bar")
        assert_equal("Stránka - bar", page.cover_placement.reload.placement_title)

        # works for atoms
        atom = create_atom(MyAtom, :cover, placement: page)
        assert_equal("Stránka - bar", atom.cover_placement.reload.placement_title)
        assert_equal("Folio::Page",
                     atom.cover_placement.placement_title_type,
                     "Uses atom's placement type")
      end
    end
  end

  test "file metadata syncs to placements on update" do
    perform_enqueued_jobs do
      file = create(:folio_file_image,
                    description: "Original caption",
                    alt: "Original alt",
                    headline: "Original headline")

      page1 = create(:folio_page)
      page1.cover = file
      page1.save!

      page2 = create(:folio_page)
      page2.cover = file
      page2.save!

      placement1 = page1.cover_placement.reload
      placement2 = page2.cover_placement.reload

      assert_equal "Original caption", placement1.description
      assert_equal "Original alt", placement1.alt
      assert_equal "Original headline", placement1.title

      file.update!(
        description: "Updated caption",
        alt: "Updated alt",
        headline: "Updated headline"
      )

      assert_equal "Updated caption", placement1.reload.description,
                   "Placement 1 description should sync from file"
      assert_equal "Updated alt", placement1.alt,
                   "Placement 1 alt should sync from file"
      assert_equal "Updated headline", placement1.title,
                   "Placement 1 title should sync from file"

      assert_equal "Updated caption", placement2.reload.description,
                   "Placement 2 description should sync from file"
      assert_equal "Updated alt", placement2.alt,
                   "Placement 2 alt should sync from file"
      assert_equal "Updated headline", placement2.title,
                   "Placement 2 title should sync from file"
    end
  end

  test "file metadata sync preserves custom placement overrides" do
    perform_enqueued_jobs do
      file = create(:folio_file_image, description: "File caption")

      page = create(:folio_page)
      page.cover = file
      page.save!

      placement = page.cover_placement.reload

      placement.update_column(:description, "Custom placement caption")

      file.update!(description: "New file caption")

      assert_equal "Custom placement caption", placement.reload.description,
                   "Custom placement description should be preserved"
    end
  end

  test "file metadata sync works for partial updates" do
    perform_enqueued_jobs do
      file = create(:folio_file_image,
                    description: "Original caption",
                    alt: "Original alt",
                    headline: "Original headline")

      page = create(:folio_page)
      page.cover = file
      page.save!

      placement = page.cover_placement.reload

      file.update!(description: "Updated caption only")

      placement.reload
      assert_equal "Updated caption only", placement.description
      assert_equal "Original alt", placement.alt
      assert_equal "Original headline", placement.title
    end
  end

  test "file metadata sync handles blank placements" do
    perform_enqueued_jobs do
      file = create(:folio_file_image, description: "File caption")

      page = create(:folio_page)
      page.cover = file
      page.save!

      placement = page.cover_placement.reload
      placement.update_column(:description, nil)
      file.update!(description: "New file caption")

      assert_equal "New file caption", placement.reload.description,
                   "Blank placement should be updated with new file value"
    end
  end

  test "file metadata sync updates to nil value" do
    perform_enqueued_jobs do
      file = create(:folio_file_image, description: "Original caption")
      page = create(:folio_page)
      page.cover = file
      page.save!

      placement = page.cover_placement.reload
      assert_equal "Original caption", placement.description

      file.update!(description: nil)

      assert_nil placement.reload.description,
                 "Placement should be updated to nil when file is updated to nil"
    end
  end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id             :integer          not null, primary key
#  placement_type :string
#  placement_id   :integer
#  file_id        :integer
#  caption        :string
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#
