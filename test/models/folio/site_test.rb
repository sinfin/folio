# frozen_string_literal: true

require "test_helper"

class Folio::SiteTest < ActiveSupport::TestCase
  test "additional_strong_params defaults to additional_params" do
    assert_equal Folio::Site.additional_params, Folio::Site.additional_strong_params
  end
end
