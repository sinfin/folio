# frozen_string_literal: true

require "test_helper"

class Folio::HasAddressesTest < ActiveSupport::TestCase
  test "should_validate_secondary_address" do
    user = Folio::User.new

    # should_validate_address > false
    user.use_secondary_address = false
    assert_not user.send(:should_validate_secondary_address?)
    user.use_secondary_address = true
    assert_not user.send(:should_validate_secondary_address?)

    user.define_singleton_method(:should_validate_address?) { true }
    # should_validate_address > true
    user.use_secondary_address = false
    assert_not user.send(:should_validate_secondary_address?)
    user.use_secondary_address = true
    assert user.send(:should_validate_secondary_address?)
  end
end
