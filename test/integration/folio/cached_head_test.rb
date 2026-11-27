# frozen_string_literal: true

require "test_helper"

class Folio::CachedHeadTest < ActionDispatch::IntegrationTest
  test "a page cached by folio_run_unless_cached renders its head once" do
    create_and_host_site
    create(:folio_page, type: "Dummy::Page::Blog::Articles::Index")

    with_global_cache do
      2.times do |i|
        get main_app.dummy_blog_articles_path

        assert_response :ok
        assert_equal 1, response.body.scan('<meta charset="utf-8"').size, "request #{i + 1}"
        assert_equal 1, response.body.scan("<title>").size, "request #{i + 1}"
      end
    end
  end

  private
    def with_global_cache
      config = Rails.application.config.action_controller
      original_perform_caching = config.perform_caching
      original_cache = Rails.cache

      config.perform_caching = true
      Rails.cache = ActiveSupport::Cache::MemoryStore.new

      yield
    ensure
      config.perform_caching = original_perform_caching
      Rails.cache = original_cache
    end
end
