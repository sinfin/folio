# frozen_string_literal: true

require 'test_helper'

class Folio::PublishableHintCellTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  test 'publishable_hint' do
    create(:folio_site)

    @page = create(:folio_page)
    visit page_path(@page, locale: @page.locale)
    assert_not page.has_css?('.folio-publishable-hint')

    @page.update!(published: false)
    assert_raises(ActiveRecord::RecordNotFound) do
      visit page_path(@page, locale: @page.locale)
    end

    account = create(:folio_admin_account)
    login_as(account, scope: :account)

    visit page_path(@page, locale: @page.locale)
    assert page.has_css?('.folio-publishable-hint')

    @page.update!(published: true)
    visit page_path(@page, locale: @page.locale)
    assert_not page.has_css?('.folio-publishable-hint')
  end
end
