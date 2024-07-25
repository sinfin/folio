# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Topics::FilterListComponentTest < Folio::ComponentTest
  def test_render
    topics = create_list(:dummy_blog_topic, 1)

    render_inline(Dummy::Blog::Topics::FilterListComponent.new(topics:, url_base: Dummy::Blog::Article))

    assert_selector(".d-blog-topics-filter-list")
  end
end
