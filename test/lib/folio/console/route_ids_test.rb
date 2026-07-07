# frozen_string_literal: true

require "test_helper"

class Folio::Console::RouteIdsTest < ActiveSupport::TestCase
  test "normalizes persisted records in nested console route arrays" do
    parent = create(:dummy_blog_topic, slug: "parent-topic")
    child = create(:dummy_blog_article, slug: "child-article")

    normalized = Folio::Console::RouteIds.normalize([:edit, :console, parent, child, { foo: "bar" }])

    assert_equal parent.id.to_s, normalized[2].to_param
    assert_equal child.id.to_s, normalized[3].to_param
    assert_equal parent.model_name, normalized[2].model_name
    assert_equal child.model_name, normalized[3].model_name
    assert_equal({ foo: "bar" }, normalized[4])
  end

  test "keeps public route arrays unchanged" do
    record = create(:dummy_blog_topic, slug: "public-topic")

    normalized = Folio::Console::RouteIds.normalize([record])

    assert_same record, normalized.first
    assert_equal "public-topic", normalized.first.to_param
  end
end
