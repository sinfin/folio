# frozen_string_literal: true

require 'test_helper'

module Folio
  class PagesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      create(:folio_site)
      @category = create(:folio_category)
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
  end
end
