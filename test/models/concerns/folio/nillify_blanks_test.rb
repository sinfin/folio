# frozen_string_literal: true

require "test_helper"

module Folio
  class PublishableTest < ActiveSupport::TestCase
    test "nillifies blanks" do
      page = create(:folio_page, title: "foo", perex: "", featured: false)
      assert_nil(page.perex)
      assert_equal(false, page.featured, "Keeps false")
    end
  end
end
