# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::NodeBuilderTest < ActiveSupport::TestCase
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
      text: :text,
      content: :rich_text,
      button_url_json: :url_json,
      position: :integer,
      folio_embed_data: :embed,
      background: %w[gray blue],
      cover: :image,
      reports: :documents,
      page: { class_name: "Folio::Page" },
      another_page: { class_name: "Folio::Page" },
      related_pages: { class_name: "Folio::Page", has_many: true }
    }

    validates :title,
              presence: true
  end

  test "convert_structure_to_hashes" do
    assert_equal({ type: :string }, Node.structure[:title])

    assert_equal({ type: :integer }, Node.structure[:position])

    assert_equal({ type: :url_json }, Node.structure[:button_url_json])

    assert_equal({
      type: :folio_attachment,
      attachment_key: :cover,
      placement_key: :cover_placement,
      file_type: "Folio::File::Image",
      has_many: false
    }, Node.structure[:cover])

    assert_equal({
      type: :folio_attachment,
      attachment_key: :reports,
      placement_key: :report_placements,
      file_type: "Folio::File::Document",
      has_many: true
    }, Node.structure[:reports])

    assert_equal({
      type: :collection,
      collection: %w[gray blue],
    }, Node.structure[:background])

    assert_equal({
      type: :relation,
      class_name: "Folio::Page",
      has_many: false
    }, Node.structure[:another_page])

    assert_equal({
      type: :relation,
      class_name: "Folio::Page",
      has_many: true
    }, Node.structure[:related_pages])

    assert_equal({ type: :embed }, Node.structure[:folio_embed_data])
  end

  test "url_json sanitizes href values" do
    node = Node.new

    # Test safe href values are preserved
    node.button_url_json = { "href" => "https://example.com", "label" => "Visit" }
    assert_equal "https://example.com", node.button_url_json["href"]
    assert_equal "Visit", node.button_url_json["label"]

    node.button_url_json = { "href" => "mailto:test@example.com", "label" => "Email" }
    assert_equal "mailto:test@example.com", node.button_url_json["href"]

    node.button_url_json = { "href" => "tel:+1234567890", "label" => "Call" }
    assert_equal "tel:+1234567890", node.button_url_json["href"]

    # Test dangerous href values are removed
    node.button_url_json = { "href" => "javascript:alert('xss')", "label" => "Click" }
    assert_nil node.button_url_json["href"]
    assert_equal "Click", node.button_url_json["label"]

    node.button_url_json = { "href" => "data:text/html,<script>alert('xss')</script>", "label" => "Click" }
    assert_nil node.button_url_json["href"]

    node.button_url_json = { "href" => "vbscript:msgbox('xss')", "label" => "Click" }
    assert_nil node.button_url_json["href"]

    node.button_url_json = { "href" => "file:///etc/passwd", "label" => "Click" }
    assert_nil node.button_url_json["href"]

    # Test that other attributes are preserved when href is removed
    node.button_url_json = { "href" => "javascript:alert('xss')", "label" => "Click", "title" => "My Link" }
    assert_nil node.button_url_json["href"]
    assert_equal "Click", node.button_url_json["label"]
    assert_equal "My Link", node.button_url_json["title"]
  end

  test "embed attribute gets normalized correctly" do
    # Test with hash input
    node = Node.new(folio_embed_data: {
      "active" => true,
      "type" => "youtube",
      "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "html" => "<iframe>...</iframe>"
    })

    assert_equal true, node.folio_embed_data["active"]
    assert_equal "youtube", node.folio_embed_data["type"]
    assert_equal "https://www.youtube.com/watch?v=dQw4w9WgXcQ", node.folio_embed_data["url"]
    assert_equal "<iframe>...</iframe>", node.folio_embed_data["html"]
  end

  test "embed attribute gets normalized from string" do
    # Test with JSON string input
    node = Node.new(folio_embed_data: '{"active": true, "type": "youtube", "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}')

    assert_equal true, node.folio_embed_data["active"]
    assert_equal "youtube", node.folio_embed_data["type"]
    assert_equal "https://www.youtube.com/watch?v=dQw4w9WgXcQ", node.folio_embed_data["url"]
  end

  test "embed attribute returns nil when inactive" do
    # Test with inactive embed
    node = Node.new(folio_embed_data: {
      "active" => false,
      "type" => "youtube",
      "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    })

    assert_nil node.folio_embed_data
  end

  test "embed attribute handles edge cases" do
    # Test with nil input
    node = Node.new(folio_embed_data: nil)
    assert_nil node.folio_embed_data

    # Test with empty hash
    node.folio_embed_data = {}
    assert_nil node.folio_embed_data

    # Test with invalid JSON string
    node.folio_embed_data = "invalid json"
    assert_nil node.folio_embed_data

    # Test with active string value
    node.folio_embed_data = { "active" => "true", "type" => "youtube" }
    assert_equal true, node.folio_embed_data["active"]
    assert_equal "youtube", node.folio_embed_data["type"]
  end

  test "embed folio_html_sanitization_config is set correctly" do
    node = Node.new
    config = node.folio_html_sanitization_config

    assert config[:enabled]
    assert_equal :unsafe_html, config[:attributes][:folio_embed_data]
  end
end
