# frozen_string_literal: true

require 'test_helper'

class TestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create(:folio_site)
  end

  test 'index_show_for' do
    visit test_path(view: 'index_show_for')
    assert(page.has_css?('.test-index-show-for-regular .f-c-index-no-records'))
    assert(page.has_css?('.test-index-show-for-group-by-day .f-c-index-no-records'))

    pages = create_list(:folio_page, 3)
    pages.first.update!(created_at: 1.year.ago)

    visit test_path(view: 'index_show_for')
    assert_equal(3 + 1, page.find_all('.test-index-show-for-regular .f-c-show-for__row').size)
    assert_equal(3 + 1, page.find_all('.test-index-show-for-group-by-day .f-c-show-for__row').size)
    assert_equal(2, page.find_all('.f-c-group-by-day').size)
  end
end
