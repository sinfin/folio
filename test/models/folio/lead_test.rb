# frozen_string_literal: true

require "test_helper"

module Folio
  class LeadTest < ActiveSupport::TestCase
    test "failed bang event returns false without changing the persisted state" do
      lead = create(:folio_lead)
      lead.note = nil

      assert_equal false, lead.to_pending!
      assert_equal "submitted", lead.reload.aasm_state
    end
  end
end
