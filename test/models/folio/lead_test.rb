# frozen_string_literal: true

require 'test_helper'

module Folio
  class LeadTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end

# == Schema Information
#
# Table name: folio_leads
#
#  id         :integer          not null, primary key
#  email      :string
#  phone      :string
#  note       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#  url        :string
#
