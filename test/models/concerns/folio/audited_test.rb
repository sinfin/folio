# frozen_string_literal: true

require 'test_helper'
require 'pry-rails'
require 'concerns/folio/audited'

class AuditedPage < Folio::Page
  include Folio::Audited

  audited only: :title
end

class Folio::AuditedTest < ActiveSupport::TestCase
  setup do
    @page = AuditedPage.create(title: 'Foo')
  end

  test 'audits' do
    assert_equal 1, @page.audits.count

    @page.update(title: 'Bar')
    assert_equal 2, @page.audits.count
  end

  test 'revisions have audits' do
    assert @page.revisions.first.audit
  end
end
