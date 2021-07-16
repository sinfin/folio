# frozen_string_literal: true

require "test_helper"

class Folio::HasAncestrySlugTest < ActiveSupport::TestCase
  class NestablePage < Folio::Page
    include Folio::HasAncestry
    include Folio::HasAncestrySlug
  end

  test "ancestry_url" do
    root = NestablePage.create!(title: "root", slug: "root")
    assert_equal "", root.ancestry_slug

    child = NestablePage.create!(title: "child", slug: "child", parent: root)
    assert_equal "root", child.ancestry_slug
    assert_equal "root/child", child.ancestry_url

    deep_child = NestablePage.create!(title: "deep_child", slug: "deep_child", parent: child)
    assert_equal "root/child", deep_child.ancestry_slug
    assert_equal "root/child/deep_child", deep_child.ancestry_url

    root.update!(slug: "new-root")
    assert_equal "", root.ancestry_slug

    child.reload
    assert_equal "new-root", child.ancestry_slug
    assert_equal "new-root/child", child.ancestry_url

    deep_child.reload
    assert_equal "new-root/child", deep_child.ancestry_slug
    assert_equal "new-root/child/deep_child", deep_child.ancestry_url

    root.destroy!

    child.reload
    assert_equal "", child.ancestry_slug
    assert_equal "child", child.ancestry_url

    deep_child.reload
    assert_equal "child", deep_child.ancestry_slug
    assert_equal "child/deep_child", deep_child.ancestry_url
  end
end
