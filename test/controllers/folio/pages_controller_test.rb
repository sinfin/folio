# frozen_string_literal: true

require 'test_helper'

class Folio::PagesControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  setup do
    create(:folio_site)
    @category = create(:folio_page)
    @page = create(:folio_page, parent: @category)

    @category_en = @category.translate!(:en)
    @category_en.update(slug: 'category_en', published: true, published_at: 1.hour.ago)
    @page_en = @page.translate!(:en)
    @page_en.update(slug: 'page_en', published: true, published_at: 1.hour.ago)
  end

  test 'root page should get show' do
    get page_url(@category, locale: :cs)
    assert_response :success
  end

  test 'category page within category should get show' do
    get page_url([@category, @page], locale: :cs)
    assert_response :success
  end

  test 'category page without category should not get show' do
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url(@page, locale: :cs)
    end
  end

  test 'translated page should get show' do
    get page_url(@category_en, locale: :en)
    assert_response :success
  end

  test 'translated page should not get show for other locales' do
    assert_raises(ActiveRecord::RecordNotFound) do
      get page_url(@category_en, locale: :cs)
    end
  end

  test 'slug/slug' do
    @category.update!(slug: 'slug', title: 'category')
    @page.update!(slug: 'deep-slug', title: 'page')
    get '/cs/slug'
    assert_response :success
    html = Nokogiri::HTML(response.body)
    assert_equal('category', html.css('h1')[0].text)

    get '/cs/slug/deep-slug'
    assert_response :success
    html = Nokogiri::HTML(response.body)
    assert_equal('page', html.css('h1')[0].text)
  end

  test 'slug change -> redirect' do
    @page.update!(parent: nil)
    old_slug = @page.slug

    get page_path(path: old_slug, locale: :cs)
    assert_response :success

    new_slug = "#{old_slug}-changed"
    @page.update!(slug: new_slug)

    get page_path(path: old_slug, locale: :cs)
    assert_redirected_to page_path(path: new_slug, locale: :cs)
  end
end
