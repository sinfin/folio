# frozen_string_literal: true

require "test_helper"

class Folio::MetaVariablesTest < ActionDispatch::IntegrationTest
  test "meta variables" do
    create(:folio_site, title: "SITE",
                               description: "SITE DESCRIPTION")
    node = create(:folio_page, title: "PAGE")

    # node without perex
    get url_for(node)

    assert_select "head title", "PAGE | SITE"
    assert_select 'meta[name="description"][content="SITE DESCRIPTION"]'

    assert_select 'meta[property="og:title"][content="PAGE | SITE"]'
    assert_select 'meta[property="og:description"][content="SITE DESCRIPTION"]'

    # node with perex
    node.update!(perex: "PAGE DESCRIPTION")
    get url_for(node)

    assert_select 'meta[name="description"][content="PAGE DESCRIPTION"]'
    assert_select 'meta[property="og:description"][content="PAGE DESCRIPTION"]'

    # page with perex & meta_description
    node.update!(meta_description: "PAGE META DESCRIPTION")
    get url_for(node)

    assert_select 'meta[name="description"][content="PAGE META DESCRIPTION"]'
    assert_select 'meta[property="og:description"][content="PAGE META DESCRIPTION"]'
  end
end
