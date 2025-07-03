# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::NodeTest < ActiveSupport::TestCase
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
      text: :text,
      content: :rich_text,
      button_url_json: :url_json,
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
                    content: RICH_TEXT_HASH.to_json,
                    button_url_json: { href: "https://example.com", label: "Example" })

    assert_equal "foo", node.title
    assert_equal "foo bar", node.text
    assert_equal RICH_TEXT_HASH, node.content
    assert_equal({ "href" => "https://example.com", "label" => "Example" }, node.button_url_json)
  end

  test "attachments" do
    cover = create(:folio_file_image)
    reports = create_list(:folio_file_document, 2)

    node = Node.new(title: "foo", cover:, reports:)

    assert_equal cover, node.cover
    assert_equal cover.id, node.cover_id

    assert_equal reports, node.reports
    assert_equal reports.map(&:id).sort, node.report_ids.sort
  end

  test "attachments via file_placements" do
    cover = create(:folio_file_image)

    node = Node.new(title: "foo", cover_placement_attributes: { file_id: cover.id })

    assert_equal cover, node.cover
    assert_equal cover.id, node.cover_id

    node.assign_attributes(cover_placement_attributes: { _destroy: "1" })

    assert_nil node.cover
    assert_nil node.cover_id
  end

  test "relations" do
    page = create(:folio_page)
    related_pages = create_list(:folio_page, 2)

    node = Node.new(title: "foo", page:, related_pages:)

    assert_equal page, node.page
    assert_equal page.id, node.page_id

    assert_equal related_pages, node.related_pages
    assert_equal related_pages.map(&:id).sort, node.related_page_ids.sort
  end

  test "to_tiptap_node_hash" do
    cover = create(:folio_file_image)
    reports = create_list(:folio_file_document, 2)
    page = create(:folio_page)
    related_pages = create_list(:folio_page, 2)

    node = Node.new(title: "foo",
                    text: "bar",
                    content: RICH_TEXT_HASH.to_json,
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
    assert_equal RICH_TEXT_HASH.to_json, hash["attrs"]["data"]["content"]
    assert_equal URL_JSON_HASH.to_json, hash["attrs"]["data"]["button_url_json"]
    assert_equal cover.id, hash["attrs"]["data"]["cover_id"]
    assert_equal reports.map(&:id).sort, hash["attrs"]["data"]["report_ids"].sort
    assert_equal page.id, hash["attrs"]["data"]["page_id"]
    assert_equal related_pages.map(&:id).sort, hash["attrs"]["data"]["related_page_ids"].sort
  end

  test "assign_attributes_from_param_attrs" do
    page = create(:folio_page)
    image = create(:folio_file_image)
    document = create(:folio_file_document)

    params_hash = {
      tiptap_node_attrs: {
        type: "Dummy::Tiptap::Node::Card",
        data: {
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

    assert_equal image, node.cover
    assert_equal image.id, node.cover_id

    assert_equal [document], node.reports
    assert_equal [document.id], node.report_ids

    assert_equal page, node.page
    assert_equal page.id, node.page_id

    assert_nil node.another_page
    assert_nil node.another_page_id
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
