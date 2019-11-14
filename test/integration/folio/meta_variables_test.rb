# frozen_string_literal: true

require 'test_helper'

class Folio::MetaVariablesTest < ActionDispatch::IntegrationTest
  test 'meta variables' do
    create(:folio_site, title: 'SITE',
                               description: 'SITE DESCRIPTION')
    node = create(:folio_page, title: 'PAGE')

    # node without perex
    visit url_for(node)

    title = page.find('title', visible: false)
    assert_equal('PAGE | SITE', title.native.text)

    description = page.find('meta[name="description"]',
                            visible: false)
    assert_equal('SITE DESCRIPTION', description[:content])

    og_title = page.find('meta[property="og:title"]',
                         visible: false)
    assert_equal('PAGE | SITE', og_title[:content])

    og_description = page.find('meta[property="og:description"]',
                               visible: false)
    assert_equal('SITE DESCRIPTION', og_description[:content])

    # node with perex
    node.update!(perex: 'PAGE DESCRIPTION')
    visit url_for(node)

    description = page.find('meta[name="description"]',
                            visible: false)
    assert_equal('PAGE DESCRIPTION', description[:content])

    og_description = page.find('meta[property="og:description"]',
                               visible: false)
    assert_equal('PAGE DESCRIPTION', og_description[:content])

    # page with perex & meta_description
    node.update!(meta_description: 'PAGE META DESCRIPTION')
    visit url_for(node)

    description = page.find('meta[name="description"]',
                            visible: false)
    assert_equal('PAGE META DESCRIPTION', description[:content])

    og_description = page.find('meta[property="og:description"]',
                               visible: false)
    assert_equal('PAGE META DESCRIPTION', og_description[:content])
  end
end
