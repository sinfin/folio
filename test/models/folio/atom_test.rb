# frozen_string_literal: true

require 'test_helper'

module Folio
  class AtomTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id         :integer          not null, primary key
#  type       :string
#  node_id    :integer
#  content    :text
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_atoms_on_node_id  (node_id)
#
