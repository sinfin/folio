# frozen_string_literal: true

require 'test_helper'

module Folio
  class FilePlacementTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id         :integer          not null, primary key
#  node_id    :integer
#  file_id    :integer
#  caption    :string
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_file_placements_on_file_id  (file_id)
#  index_folio_file_placements_on_node_id  (node_id)
#
