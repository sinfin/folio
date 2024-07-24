# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::TopicsControllerTest < Folio::BaseControllerTest
  test "show" do
    topic = create(:dummy_blog_topic)
    get url_for(topic)
    assert_response :ok
    assert_select(".d-blog-articles-card", 0)

    create(:dummy_blog_article, topics: [topic])

    get url_for(topic)
    assert_response :ok
    assert_select(".d-blog-articles-card")

    topic.update!(published: false)

    assert_raises(ActiveRecord::RecordNotFound) { get url_for(topic) }

    get url_for([topic, Folio::Publishable::PREVIEW_PARAM_NAME => topic.preview_token])
    assert_response(:ok)
  end
end
