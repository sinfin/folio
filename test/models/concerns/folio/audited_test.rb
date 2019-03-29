# frozen_string_literal: true

require 'test_helper'

class Folio::AuditedTest < ActiveSupport::TestCase
  setup do
    @page = create(:folio_page, title: 'Foo')
  end

  test 'audits' do
    assert_equal 1, @page.audits.count

    @page.update(title: 'Bar')
    assert_equal 2, @page.audits.count
  end

  test 'revision has audit' do
    assert @page.revisions.first.audit
  end
end
