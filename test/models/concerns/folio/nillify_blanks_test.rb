# frozen_string_literal: true

require "test_helper"

module Folio
  class PublishableTest < ActiveSupport::TestCase
    test "nillifies blanks" do
      page = create(:folio_page, title: "foo", perex: "", published: false)
      assert_nil(page.perex)
      assert_equal(false, page.published, "Keeps false")
    end
  end
end
