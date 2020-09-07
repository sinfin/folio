# frozen_string_literal: true

require "test_helper"

class Folio::FilePlacementTest < ActiveSupport::TestCase
  class MyAtom < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
  end

  test "placement_title" do
    I18n.with_locale(:cs) do
      page = create(:folio_page, title: "foo")
      page.cover = create(:folio_image)

      # works
      assert_equal("Stránka - foo", page.cover_placement.placement_title)
      assert_equal("Folio::Page", page.cover_placement.placement_title_type)

      # updates through touch
      page.update!(title: "bar")
      assert_equal("Stránka - bar", page.cover_placement.reload.placement_title)

      # works for atoms
      atom = create_atom(MyAtom, :cover, placement: page)
      assert_equal("Stránka - bar", atom.cover_placement.placement_title)
      assert_equal("Folio::Page",
                   atom.cover_placement.placement_title_type,
                   "Uses atom's placement type")
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
