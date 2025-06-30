# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::NodeTest < ActiveSupport::TestCase
  class Node < Folio::Tiptap::Node
    tiptap_node title: :string,
                content: :text,
                button_url_json: :url_json,
                image: :image,
                documents: :documents,
                page: { class_name: "Folio::Page" },
                related_pages: { class_name: "Folio::Page", has_many: true }

    validates :title,
              presence: true
  end

  test "attributes" do
    node = Node.new(title: "foo",
                    content: "foo bar",
                    button_url_json: { href: "https://example.com", label: "Example" })

    assert_equal "foo", node.title
    assert_equal "foo bar", node.content
    assert_equal({ "href" => "https://example.com", "label" => "Example" }, node.button_url_json)
  end

  test "attachments" do
    image = create(:folio_file_image)
    documents = create_list(:folio_file_document, 2)

    node = Node.new(title: "foo", image:, documents:)

    assert_equal image, node.image
    assert_equal image.id, node.image_id

    assert_equal documents, node.documents
    assert_equal documents.map(&:id).sort, node.documents_ids.sort
  end

  test "relations" do
    page = create(:folio_page)
    related_pages = create_list(:folio_page, 2)

    node = Node.new(title: "foo", page:, related_pages:)

    assert_equal page, node.page
    assert_equal page.id, node.page_id

    assert_equal related_pages, node.related_pages
    assert_equal related_pages.map(&:id).sort, node.related_pages_ids.sort
  end

  test "to_tiptap_node_hash" do
    image = create(:folio_file_image)
    documents = create_list(:folio_file_document, 2)
    page = create(:folio_page)
    related_pages = create_list(:folio_page, 2)

    node = Node.new(title: "foo",
                    content: "bar",
                    image:,
                    documents:,
                    page:,
                    related_pages:,
                    button_url_json: { href: "foo", label: "bar" })

    hash = node.to_tiptap_node_hash

    assert_equal "folioTiptapNode", hash["type"]
    assert_equal 1, hash["attrs"]["version"]
    assert_equal "Folio::Tiptap::NodeTest::Node", hash["attrs"]["type"]
    assert_equal "foo", hash["attrs"]["data"]["title"]
    assert_equal "foo", hash["attrs"]["data"]["button_url_json"]["href"]
    assert_equal image.id, hash["attrs"]["data"]["image_id"]
    assert_equal documents.map(&:id).sort, hash["attrs"]["data"]["documents_ids"].sort
    assert_equal page.id, hash["attrs"]["data"]["page_id"]
    assert_equal related_pages.map(&:id).sort, hash["attrs"]["data"]["related_pages_ids"].sort
  end
end

# == Schema Information
#
# Table name: folio_leads
#
#  id              :integer          not null, primary key
#  email           :string
#  phone           :string
#  note            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  name            :string
#  url             :string
#  additional_data :json
#  state           :string           default("submitted")
#  visit_id        :integer
#
# Indexes
#
#  index_folio_leads_on_visit_id  (visit_id)
#
