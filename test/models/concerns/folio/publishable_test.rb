# frozen_string_literal: true

require 'test_helper'

class Folio::PublishableTest < ActiveSupport::TestCase
  test 'published, published_or_admin' do
    assert_equal(0, Folio::Page.published.count)
    assert_equal(0, Folio::Page.unpublished.count)
    assert_equal(0, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    node = create(:folio_node, :unpublished)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    node.update!(published: true)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    node.update!(published: false, published_at: 1.hour.ago)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    node.update!(published: true, published_at: 1.hour.ago)
    assert_equal(1, Folio::Page.published.count)
    assert_equal(0, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(1, Folio::Page.published_or_admin(false).count)

    node.update!(published: true, published_at: 1.hour.from_now)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)
  end
end

# == Schema Information
#
# Table name: folio_nodes
#
#  id               :integer          not null, primary key
#  site_id          :integer
#  title            :string
#  slug             :string
#  perex            :text
#  content          :text
#  meta_title       :string(512)
#  meta_description :string(1024)
#  code             :string
#  ancestry         :string
#  type             :string
#  featured         :boolean
#  position         :integer
#  published        :boolean
#  published_at     :datetime
#  original_id      :integer
#  locale           :string(6)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_folio_nodes_on_ancestry      (ancestry)
#  index_folio_nodes_on_code          (code)
#  index_folio_nodes_on_featured      (featured)
#  index_folio_nodes_on_locale        (locale)
#  index_folio_nodes_on_original_id   (original_id)
#  index_folio_nodes_on_position      (position)
#  index_folio_nodes_on_published     (published)
#  index_folio_nodes_on_published_at  (published_at)
#  index_folio_nodes_on_site_id       (site_id)
#  index_folio_nodes_on_slug          (slug)
#  index_folio_nodes_on_type          (type)
#
