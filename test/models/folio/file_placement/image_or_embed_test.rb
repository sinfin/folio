# frozen_string_literal: true

require "test_helper"

class Folio::FilePlacementTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "validate_file_or_embed" do
    file = create(:folio_file_image)

    page = create(:folio_page)

    file_placement = Folio::FilePlacement::ImageOrEmbed.new(file:, placement: page)
    assert file_placement.valid?
    assert_equal [file_placement.id], page.image_or_embed_placements.pluck(:id)

    file_placement.file = nil
    assert_not file_placement.valid?
    assert file_placement.errors[:file].present?

    file_placement.file = file
    file_placement.folio_embed_data = { "active" => true }
    assert_not file_placement.valid?
    assert file_placement.errors[:folio_embed_data].present?

    file_placement.folio_embed_data = { "active" => true, "html" => "<iframe></iframe>" }
    assert file_placement.valid?
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
