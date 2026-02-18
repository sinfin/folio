# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::NodeTest < ActiveSupport::TestCase
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
      text: :text,
      content: :rich_text,
      button_url_json: :url_json,
      position: :integer,
      background: %w[gray blue],
      boolean_from_collection: [true, false],
      cover: :image,
      reports: :documents,
      page: { class_name: "Folio::Page" },
      another_page: { class_name: "Folio::Page" },
      related_pages: { class_name: "Folio::Page", has_many: true }
    }

    validates :title,
              presence: true
  end

  RICH_TEXT_HASH = { "type" => "doc", "content" => [{ "type" => "paragraph", "attrs" => { "textAlign" => nil }, "content" => [{ "type" => "text", "text" => "lorem" }] }, { "type" => "paragraph", "attrs" => { "textAlign" => nil }, "content" => [{ "type" => "text", "text" => "ipsum" }] }] }

  URL_JSON_HASH = { href: "foo", label: "bar" }

  test "attributes" do
    node = Node.new(title: "foo",
                    text: "foo bar",
                    position: "3",
                    content: RICH_TEXT_HASH.to_json,
                    button_url_json: { href: "https://example.com", label: "Example" })

    assert_equal "foo", node.title
    assert_equal "foo bar", node.text
    assert_equal 3, node.position
    assert_equal RICH_TEXT_HASH, node.content
    assert_equal({ "href" => "https://example.com", "label" => "Example" }, node.button_url_json)
  end

  test "attachments" do
    cover = create(:folio_file_image)
    reports = create_list(:folio_file_document, 2)

    node = Node.new(title: "foo", cover:, reports:)

    assert node.cover.is_a?(Folio::File::Image)
    assert_equal cover.id, node.cover.id

    assert node.cover_placement.is_a?(Folio::FilePlacement::Tiptap)
    assert_equal cover.id, node.cover_placement.file_id

    assert node.cover_placement_attributes
    assert_equal cover.id, node.cover_placement_attributes["file_id"]

    assert_equal 2, node.reports.size

    assert node.reports[0].is_a?(Folio::File::Document)
    assert node.reports[1].is_a?(Folio::File::Document)

    assert_equal reports.map(&:id).sort, node.reports.map(&:id).sort

    assert_equal 2, node.report_placements.size

    assert node.report_placements[0].is_a?(Folio::FilePlacement::Tiptap)
    assert node.report_placements[1].is_a?(Folio::FilePlacement::Tiptap)
    assert_equal reports.map(&:id).sort, node.report_placements.map(&:file_id).sort

    assert node.report_placements_attributes
    assert_equal reports.map(&:id).sort, node.report_placements_attributes.map { |h| h["file_id"] }.sort
  end

  test "attachments via file_placements" do
    cover = create(:folio_file_image)

    node = Node.new(title: "foo", cover_placement_attributes: { file_id: cover.id })

    assert_equal cover, node.cover
    assert_equal cover.id, node.cover_placement.file_id

    node.assign_attributes(cover_placement_attributes: { _destroy: "1" })

    assert_nil node.cover
    assert_nil node.cover_placement
  end

  test "relations" do
    page = create(:folio_page)
    related_pages = create_list(:folio_page, 2)

    node = Node.new(title: "foo", page:, related_pages:)

    assert_equal page, node.page
    assert_equal page.id, node.page_id

    assert_equal related_pages.map(&:id).sort, node.related_pages.map(&:id).sort
    assert_equal related_pages.map(&:id).sort, node.related_page_ids.sort
  end

  test "to_tiptap_node_hash" do
    cover = create(:folio_file_image)
    reports = create_list(:folio_file_document, 2)
    page = create(:folio_page)
    related_pages = create_list(:folio_page, 2)

    node = Node.new(title: "foo",
                    text: "bar",
                    background: "blue",
                    content: RICH_TEXT_HASH.to_json,
                    position: 3,
                    cover:,
                    reports:,
                    page:,
                    related_pages:,
                    button_url_json: URL_JSON_HASH)

    hash = node.to_tiptap_node_hash

    assert_equal "folioTiptapNode", hash["type"]
    assert_equal 1, hash["attrs"]["version"]
    assert_equal "Folio::Tiptap::NodeTest::Node", hash["attrs"]["type"]
    assert_equal "foo", hash["attrs"]["data"]["title"]
    assert_equal 3, hash["attrs"]["data"]["position"]
    assert_equal "blue", hash["attrs"]["data"]["background"]
    assert_equal RICH_TEXT_HASH.to_json, hash["attrs"]["data"]["content"]
    assert_equal URL_JSON_HASH.to_json, hash["attrs"]["data"]["button_url_json"]
    assert_equal cover.id, hash["attrs"]["data"]["cover_placement_attributes"]["file_id"]
    assert_equal reports.map(&:id).sort, hash["attrs"]["data"]["report_placements_attributes"].map { |attrs| attrs["file_id"] }.sort
    assert_equal page.id, hash["attrs"]["data"]["page_id"]
    assert_equal related_pages.map(&:id).sort, hash["attrs"]["data"]["related_page_ids"].sort
  end

  test "collection [true, false] allows assigning true and false and serializes both in to_tiptap_node_hash" do
    node_false = Node.new(title: "test", boolean_from_collection: false)
    assert_equal false, node_false.boolean_from_collection, "assigning false to collection [true, false] should work"
    hash_false = node_false.to_tiptap_node_hash
    assert hash_false["attrs"]["data"].key?("boolean_from_collection"),
           "boolean_from_collection should be present in serialized data (false must not be omitted by present?)"
    assert_equal false, hash_false["attrs"]["data"]["boolean_from_collection"],
                 "serialized data should contain false"

    node_true = Node.new(title: "test", boolean_from_collection: true)
    assert_equal true, node_true.boolean_from_collection, "assigning true to collection [true, false] should work"
    hash_true = node_true.to_tiptap_node_hash
    assert hash_true["attrs"]["data"].key?("boolean_from_collection"),
           "boolean_from_collection should be present in serialized data"
    assert_equal true, hash_true["attrs"]["data"]["boolean_from_collection"],
                 "serialized data should contain true"
  end

  test "assign_attributes_from_param_attrs" do
    page = create(:folio_page)
    image = create(:folio_file_image)
    document = create(:folio_file_document)

    params_hash = {
      tiptap_node_attrs: {
        type: "Dummy::Tiptap::Node::Card",
        data: {
          background: "blue",
          cover_placement_attributes: { id: "", file_id: "#{image.id}" },
          title: "a",
          text: "",
          button_url_json: "{}",
          page_id: "#{page.id}",
          another_page_id: "",
          report_placements_attributes: {
            "1751435538853" => { id: "", file_id: "#{document.id}", position: "0" }
          }
        }
      }
    }

    params = ActionController::Parameters.new(params_hash)

    node = Node.new
    node.assign_attributes_from_param_attrs(params[:tiptap_node_attrs])

    assert_equal "a", node.title
    assert_equal "", node.text
    assert_equal({}, node.button_url_json)
    assert_equal("blue", node.background)

    assert_equal image, node.cover
    assert_equal image.id, node.cover.id
    assert_equal image.id, node.cover_placement.file_id
    assert_equal image.id, node.cover_placement_attributes["file_id"]

    assert_equal [document.id], node.reports.map(&:id)
    assert_equal [document.id], node.report_placements.map(&:file_id)
    assert_equal [document.id], node.report_placements_attributes.map { |attrs| attrs["file_id"] }

    assert_equal page, node.page
    assert_equal page.id, node.page_id

    assert_nil node.another_page
    assert_nil node.another_page_id
  end
end
