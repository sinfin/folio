# frozen_string_literal: true

require 'test_helper'

class MetaVariablesTest < ActionDispatch::IntegrationTest
  test 'meta variables' do
    site = create(:folio_site, title: 'SITE',
                               description: 'SITE DESCRIPTION')
    node = create(:folio_page, site: site,
                               title: 'PAGE')

    # node without perex
    visit page_path(path: node.slug, locale: node.locale)

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
    assert_equal('SITE DESCRIPTION', description[:content])

    # node with perex
    node.update!(perex: 'PAGE DESCRIPTION')
    visit page_path(path: node.slug, locale: node.locale)

    description = page.find('meta[name="description"]',
                            visible: false)
    assert_equal('PAGE DESCRIPTION', description[:content])

    og_description = page.find('meta[property="og:description"]',
                               visible: false)
    assert_equal('PAGE DESCRIPTION', description[:content])

    # node with perex & meta_description
    node.update!(meta_description: 'PAGE META DESCRIPTION')
    visit page_path(path: node.slug, locale: node.locale)

    description = page.find('meta[name="description"]',
                            visible: false)
    assert_equal('PAGE META DESCRIPTION', description[:content])

    og_description = page.find('meta[property="og:description"]',
                               visible: false)
    assert_equal('PAGE META DESCRIPTION', description[:content])
  end
end
