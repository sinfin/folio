# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::TopicsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create_and_host_site
  end

  test "show" do
    article = create(:dummy_blog_topic)
    get url_for(article)
    assert_response :ok

    article.update!(published: false)

    assert_raises(ActiveRecord::RecordNotFound) { get url_for(article) }

    sign_in create(:folio_admin_account)
    get url_for(article)
    assert_response(:ok)
  end
end
