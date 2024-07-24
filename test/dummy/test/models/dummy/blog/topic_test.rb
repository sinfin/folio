# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::TopicTest < ActiveSupport::TestCase
  test "cannot change locale with offending articles" do
    topic = create(:dummy_blog_topic, locale: "cs")
    create(:dummy_blog_article, locale: "cs", topics: [topic])

    topic.locale = "en"
    assert_not topic.valid?
    assert topic.errors[:locale]
  end

  test "cannot change site with offending articles" do
    site = create_and_host_site
    site_2 = create_site(force: true)

    topic = create(:dummy_blog_topic, site:)
    create(:dummy_blog_article, topics: [topic], site:)

    topic.site = site_2
    assert_not topic.valid?
    assert topic.errors[:site]
  end
end
