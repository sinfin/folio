# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Topics::TagListCellTest < Cell::TestCase
  test "show" do
    model = create_list(:dummy_blog_topic, 1)
    html = cell("dummy/blog/topics/tag_list", model).(:show)
    assert html.has_css?(".d-blog-topics-tag-list")
  end
end
