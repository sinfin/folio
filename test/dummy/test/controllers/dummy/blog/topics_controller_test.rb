# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::TopicsControllerTest < Folio::BaseControllerTest
  test "show" do
    topic = create(:dummy_blog_topic)
    get url_for(topic)
    assert_response :ok

    topic.update!(published: false)

    assert_raises(ActiveRecord::RecordNotFound) { get url_for(topic) }

    get url_for([topic, Folio::Publishable::PREVIEW_PARAM_NAME => topic.preview_token])
    assert_response(:ok)
  end
end
