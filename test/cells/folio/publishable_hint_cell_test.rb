# frozen_string_literal: true

require 'test_helper'

class Folio::PublishableHintCellTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  test 'publishable_hint' do
    create(:folio_site)

    @node = create(:folio_page)
    visit page_path(@node, locale: @node.locale)
    assert_not page.has_css?('.folio-publishable-hint')

    @node.update!(published: false)
    assert_raises(ActiveRecord::RecordNotFound) do
      visit page_path(@node, locale: @node.locale)
    end

    account = create(:folio_admin_account)
    login_as(account, scope: :account)

    visit page_path(@node, locale: @node.locale)
    assert page.has_css?('.folio-publishable-hint')

    @node.update!(published: true)
    visit page_path(@node, locale: @node.locale)
    assert_not page.has_css?('.folio-publishable-hint')
  end
end
