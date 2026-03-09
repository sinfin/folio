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
      boolean_from_collection: [true, false],
      number_from_collection: [1, 2, 3],
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
      type: :collection,
      collection: [true, false],
    }, Node.structure[:boolean_from_collection])

    assert_equal({
      type: :collection,
      collection: [1, 2, 3],
    }, Node.structure[:number_from_collection])

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

  test "boolean_from_collection uses boolean type and stores true/false not strings" do
    # NodeBuilder sets type: :boolean for collection [true, false], so values are booleans not strings
    node_true = Node.new(title: "test", boolean_from_collection: true)
    assert_equal true, node_true.boolean_from_collection
    assert node_true.boolean_from_collection == true, "should be boolean true"
    assert_not_equal "true", node_true.boolean_from_collection, "should not be string"

    node_false = Node.new(title: "test", boolean_from_collection: false)
    assert_equal false, node_false.boolean_from_collection
    assert node_false.boolean_from_collection == false, "should be boolean false"
    assert_not_equal "false", node_false.boolean_from_collection, "should not be string"
  end

  test "boolean_from_collection coerces string params to boolean" do
    # From request params, values often come as strings; boolean type should coerce them
    node = Node.new(title: "test", boolean_from_collection: "true")
    assert_equal true, node.boolean_from_collection
    assert node.boolean_from_collection.is_a?(TrueClass)

    node.boolean_from_collection = "false"
    assert_equal false, node.boolean_from_collection
    assert node.boolean_from_collection.is_a?(FalseClass)

    node.boolean_from_collection = "1"
    assert_equal true, node.boolean_from_collection

    node.boolean_from_collection = "0"
    assert_equal false, node.boolean_from_collection
  end

  test "integer_collection coerces string params to integer" do
    # From request params, values often come as strings; integer collection should coerce them
    node = Node.new(title: "test", number_from_collection: "42")
    assert_equal 42, node.number_from_collection
    assert node.number_from_collection.is_a?(Integer)

    node.number_from_collection = "7"
    assert_equal 7, node.number_from_collection
    assert node.number_from_collection.is_a?(Integer)
  end

  test "collection setters use nil for invalid values instead of raising" do
    node = Node.new(title: "test")

    node.boolean_from_collection = "nope"
    assert_nil node.boolean_from_collection

    node.boolean_from_collection = {}
    assert_nil node.boolean_from_collection

    node.number_from_collection = {}
    assert_nil node.number_from_collection
  end

  test "boolean_from_collection serializes as boolean in to_tiptap_node_hash not string" do
    node = Node.new(title: "test", boolean_from_collection: false)
    hash = node.to_tiptap_node_hash
    assert hash["attrs"]["data"].key?("boolean_from_collection")
    assert_equal false, hash["attrs"]["data"]["boolean_from_collection"],
                 "serialized value must be boolean false, not string \"false\""
    assert hash["attrs"]["data"]["boolean_from_collection"].is_a?(FalseClass)

    node.boolean_from_collection = true
    hash = node.to_tiptap_node_hash
    assert_equal true, hash["attrs"]["data"]["boolean_from_collection"],
                 "serialized value must be boolean true, not string \"true\""
    assert hash["attrs"]["data"]["boolean_from_collection"].is_a?(TrueClass)
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

  test "tiptap_config validates toolbar hash structure successfully" do
    # Define a node class with valid toolbar configuration
    valid_node_class = Class.new(Folio::Tiptap::Node) do
      tiptap_node structure: {
        title: :string,
      }, tiptap_config: {
        icon: "image",
        toolbar_slot: "after_layouts",
      }
    end

    # Should initialize without error
    node = valid_node_class.new
    assert_not_nil node
  end

  test "tiptap_config fails with invalid toolbar hash structure" do
    # Test with non-String icon value
    assert_raises(ArgumentError) do
      Class.new(Folio::Tiptap::Node) do
        tiptap_node structure: {
          title: :string,
        }, tiptap_config: {
          icon: 123,
          toolbar_slot: "after_layouts",
        }
      end
    end

    # Test with non-String toolbar_slot value
    assert_raises(ArgumentError) do
      Class.new(Folio::Tiptap::Node) do
        tiptap_node structure: {
          title: :string,
        }, tiptap_config: {
          icon: "image",
          toolbar_slot: true,
        }
      end
    end
  end
end
