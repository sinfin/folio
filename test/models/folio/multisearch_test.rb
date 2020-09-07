# frozen_string_literal: true

require "test_helper"

class Folio::MultisearchTest < ActiveSupport::TestCase
  test "pages" do
    search = PgSearch.multisearch("foo")
    assert search.blank?

    page = create(:folio_page, title: "foo bar")

    search = PgSearch.multisearch("foo")
    assert_equal(1, search.size)
    assert_equal(page.id, search.first.searchable.id)
  end
end
