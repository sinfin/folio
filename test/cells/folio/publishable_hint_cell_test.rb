# frozen_string_literal: true

require "test_helper"

class Folio::PublishableHintCellTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  test "publishable_hint" do
    create(:folio_site)

    @page = create(:folio_page)
    get url_for([@page, locale: @page.locale])
    assert_select ".folio-publishable-hint", false

    @page.update!(published: false)
    assert_raises(ActiveRecord::RecordNotFound) do
      get url_for([@page, locale: @page.locale])
    end

    account = create(:folio_admin_account)
    login_as(account, scope: :account)

    get url_for([@page, locale: @page.locale])

    assert_redirected_to url_for([:preview, @page]) # , locale: @page.locale])
    follow_redirect!
    assert_select ".folio-publishable-hint"

    @page.update!(published: true)
    get url_for([@page, locale: @page.locale])
    assert_select ".folio-publishable-hint", false
  end
end
