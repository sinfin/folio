# frozen_string_literal: true

require 'test_helper'

class Folio::HasVersionsTest < ActiveSupport::TestCase
  test 'versions' do
    page = create(:folio_page, title: 'Foo')
    assert_equal 1, page.versions.count

    page.update(title: 'Bar')
    assert_equal 2, page.versions.count
  end
end
