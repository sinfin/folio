# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Topics::TagsListComponentTest < Folio::ComponentTest
  def test_render
    topics = create_list(:dummy_blog_topic, 1)

    render_inline(Dummy::Blog::Topics::TagsListComponent.new(topics:))

    assert_selector(".d-blog-topics-tags-list")
  end
end
