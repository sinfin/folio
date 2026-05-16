# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::TextExtractorTest < ActiveSupport::TestCase
  class IgnoredNode < Folio::Tiptap::Node
    tiptap_node structure: { title: :string }
  end

  test "returns empty string for blank input" do
    assert_equal "", Folio::Tiptap.extract_text(nil)
    assert_equal "", Folio::Tiptap.extract_text({})
    assert_equal "", Folio::Tiptap.extract_text([])
  end

  test "extracts text from full column hash, inner doc, and array" do
    text = "Hello world"
    column_hash = TiptapHelper.tiptap_text_content(text)
    inner_doc = column_hash[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]]
    array = inner_doc["content"]

    assert_equal text, Folio::Tiptap.extract_text(column_hash)
    assert_equal text, Folio::Tiptap.extract_text(inner_doc)
    assert_equal text, Folio::Tiptap.extract_text(array)
  end

  test "extracts paragraphs and headings, joins with space, collapses whitespace" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "heading", "attrs" => { "level" => 1 },
          "content" => [{ "type" => "text", "text" => "Title" }] },
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "First   paragraph." }] },
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Second paragraph." }] },
      ]
    }

    assert_equal "Title First paragraph. Second paragraph.", Folio::Tiptap.extract_text(doc)
  end

  test "ignores marks (bold, link) but keeps the underlying text" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [
          { "type" => "text", "text" => "Bold ", "marks" => [{ "type" => "bold" }] },
          { "type" => "text", "text" => "link",
            "marks" => [{ "type" => "link", "attrs" => { "href" => "https://example.com" } }] },
        ] }
      ]
    }

    assert_equal "Bold link", Folio::Tiptap.extract_text(doc)
  end

  test "skips default-ignored types (hardBreak, horizontalRule)" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [
          { "type" => "text", "text" => "before" },
          { "type" => "hardBreak" },
          { "type" => "text", "text" => "after" },
        ] },
        { "type" => "horizontalRule" },
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "more" }] },
      ]
    }

    assert_equal "before after more", Folio::Tiptap.extract_text(doc)
  end

  test "extracts string and text attributes from a folio tiptap node" do
    doc = doc_with_node(Dummy::Tiptap::Node::Card, {
      "title" => "Card title",
      "text"  => "Card description",
    })

    assert_equal "Card title Card description", Folio::Tiptap.extract_text(doc)
  end

  test "extracts rich_text attributes recursively from a folio tiptap node" do
    # rich_text values are serialized to JSON in to_tiptap_node_hash, so the
    # stored shape inside tiptap_content is a String. The node setter parses it.
    rich_text_json = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Inside rich text." }] }
      ]
    }.to_json

    doc = doc_with_node(Dummy::Tiptap::Node::Card, {
      "title"   => "Outer",
      "content" => rich_text_json,
    })

    assert_equal "Outer Inside rich text.", Folio::Tiptap.extract_text(doc)
  end

  test "ignores non-textual attribute types (image, integer, relation, embed, url_json, collection)" do
    cover = create(:folio_file_image)

    doc = doc_with_node(Dummy::Tiptap::Node::Card, {
      "title"           => "Visible",
      "cover_id"        => cover.id,
      "background"      => "blue",
      "button_url_json" => { "href" => "https://example.com", "label" => "Should be skipped" },
    })

    result = Folio::Tiptap.extract_text(doc)

    assert_equal "Visible", result
    assert_not_includes result, "blue"
    assert_not_includes result, "Should be skipped"
    assert_not_includes result, "example.com"
  end

  test "skips folio tiptap nodes whose class is in additional_ignored_node_types" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Keep" }] },
        folio_tiptap_node(IgnoredNode, { "title" => "Drop me" }),
      ]
    }

    result = Folio::Tiptap.extract_text(
      doc,
      additional_ignored_node_types: [IgnoredNode.name],
    )

    assert_equal "Keep", result
  end

  test "skips prose-mirror types added via additional_ignored_node_types" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Keep" }] },
        { "type" => "blockquote", "content" => [
          { "type" => "paragraph",
            "content" => [{ "type" => "text", "text" => "Drop" }] }
        ] }
      ]
    }

    assert_equal "Keep",
                 Folio::Tiptap.extract_text(doc, additional_ignored_node_types: ["blockquote"])
  end

  test "logs and skips folio tiptap nodes with an unknown class" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Real" }] },
        { "type" => "folioTiptapNode",
          "attrs" => { "type" => "Does::Not::Exist", "version" => 1, "data" => { "title" => "ghost" } } },
      ]
    }

    log_io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_io)

    begin
      assert_equal "Real", Folio::Tiptap.extract_text(doc)
    ensure
      Rails.logger = original_logger
    end

    assert_includes log_io.string, "Does::Not::Exist"
  end

  test "collapses whitespace runs and strips" do
    doc = {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "  leading and trailing  " }] },
        { "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "  multiple\n\nlines\t\there  " }] },
      ]
    }

    assert_equal "leading and trailing multiple lines here", Folio::Tiptap.extract_text(doc)
  end

  private
    def folio_tiptap_node(klass, data)
      {
        "type" => "folioTiptapNode",
        "attrs" => { "type" => klass.name, "version" => 1, "data" => data }
      }
    end

    def doc_with_node(klass, data)
      {
        "type" => "doc",
        "content" => [folio_tiptap_node(klass, data)]
      }
    end
end
