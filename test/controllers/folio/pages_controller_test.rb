# frozen_string_literal: true

require "test_helper"

class Folio::PagesControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  setup do
    create_and_host_site
    @page = create(:folio_page)
  end

  test "root page should get show" do
    get url_for(@page)
    assert_response :ok
  end

  test "slug change -> redirect" do
    old_slug = @page.slug

    get url_for(@page)
    assert_response :ok

    new_slug = "#{old_slug}-changed"
    @page.update!(slug: new_slug)

    get "/#{new_slug}"
    assert_response :ok

    get "/#{old_slug}"
    assert_redirected_to url_for(@page)
  end

  class ::NonPublicPage < Folio::Page
    def self.public?
      false
    end
  end

  test "public?" do
    get url_for(@page)
    assert_response :ok

    @page.becomes!(NonPublicPage)
    @page.save!
    assert_raises(ActiveRecord::RecordNotFound) { get url_for(@page) }
  end

  class ::NonPublicRedirectPage < Folio::Page
    def self.public_rails_path
      :root_path
    end
  end

  test "public_rails_path" do
    get url_for(@page)
    assert_response :ok

    @page.becomes!(NonPublicRedirectPage)
    @page.save!
    get url_for(@page)
    assert_redirected_to(root_path)
  end
end
