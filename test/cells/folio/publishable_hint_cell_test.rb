# frozen_string_literal: true

require "test_helper"

class Folio::PublishableHintCellTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  test "publishable_hint" do
    create_and_host_site

    @page = create(:folio_page)
    get url_for([@page, locale: @page.locale])
    assert_select ".folio-publishable-hint", false

    @page.update!(published: false)
    assert_raises(ActiveRecord::RecordNotFound) do
      get url_for([@page, locale: @page.locale])
    end

    account = create(:folio_account)
    login_as(account, scope: :account)

    get url_for([@page, locale: @page.locale])
    assert_response(:ok)

    assert_select ".folio-publishable-hint"

    @page.update!(published: true)
    get url_for([@page, locale: @page.locale])
    assert_select ".folio-publishable-hint", false
  end
end
