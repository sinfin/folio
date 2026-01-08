# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ModelTest < ActiveSupport::TestCase
  test "has_folio_tiptap_content with locales registers locale-suffixed fields" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content(locales: %i[cs en])

    assert_equal %w[tiptap_content_cs tiptap_content_en], model_class.folio_tiptap_fields.sort
  end

  test "has_folio_tiptap_content without locales maintains existing behavior" do
    model_class = Class.new(Folio::ApplicationRecord) do
      self.table_name = "folio_pages"
      include Folio::Tiptap::Model
    end

    model_class.has_folio_tiptap_content

    assert_equal %w[tiptap_content], model_class.folio_tiptap_fields
  end

  test "convert_titap_fields_to_hashes" do
    page = create(:folio_page)

    Folio::Page.stub(:has_folio_tiptap?, true) do
      page.tiptap_content = dummy_tiptap_doc.to_json
      assert page.tiptap_content.is_a?(Hash)
      assert_equal(dummy_tiptap_doc, page.tiptap_content)
    end
  end

  test "sanitizes all texts" do
    page = create(:folio_page)

    Folio::Page.stub(:has_folio_tiptap?, true) do
      page.tiptap_content = xss_tiptap_doc.to_json
      assert_equal(sanitized_tiptap_doc, page.tiptap_content, "sanitizes content passed a string")

      page.tiptap_content = dummy_tiptap_doc
      assert_equal(dummy_tiptap_doc, page.tiptap_content)

      page.tiptap_content = xss_tiptap_doc
      assert_equal(sanitized_tiptap_doc, page.tiptap_content, "sanitizes content passed a hash")
    end
  end

  test "requires doc as a root node" do
    page = create(:folio_page)

    Folio::Page.stub(:has_folio_tiptap?, true) do
      page.tiptap_content = {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Hello world"
            }
          ]
        }
      }

      assert_not page.valid?
      assert page.errors[:tiptap_content].present?, "requires doc as a root node"

      page.tiptap_content = {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Hello world"
                }
              ]
            }
          ]
        }
      }

      assert page.valid?
    end
  end

  test "validates folioTiptapPages node count" do
    page = create(:folio_page)

    Folio::Page.stub(:has_folio_tiptap?, true) do
      # Test with no folioTiptapPages nodes - should be valid
      page.tiptap_content = {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Hello world"
                }
              ]
            }
          ]
        }
      }

      assert page.valid?, "should be valid with no folioTiptapPages nodes"

      # Test with one folioTiptapPages node - should be valid
      page.tiptap_content = {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "folioTiptapPages",
              "content" => []
            },
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Hello world"
                }
              ]
            }
          ]
        }
      }

      assert page.valid?, "should be valid with one folioTiptapPages node"

      # Test with multiple folioTiptapPages nodes - should be invalid
      page.tiptap_content = {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "folioTiptapPages",
              "content" => []
            },
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Hello world"
                }
              ]
            },
            {
              "type" => "folioTiptapPages",
              "content" => []
            }
          ]
        }
      }

      assert_not page.valid?, "should be invalid with multiple folioTiptapPages nodes"
      assert page.errors[:tiptap_content].present?, "should have tiptap_content error"

      # Test with nested folioTiptapPages nodes - should be invalid
      page.tiptap_content = {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "someContainer",
              "content" => [
                {
                  "type" => "folioTiptapPages",
                  "content" => []
                }
              ]
            },
            {
              "type" => "folioTiptapPages",
              "content" => []
            }
          ]
        }
      }

      assert_not page.valid?, "should be invalid with nested folioTiptapPages nodes"
      assert page.errors[:tiptap_content].present?, "should have tiptap_content error for nested nodes"
    end
  end

  test "keeps a set of Folio::FilePlacement::Tiptap placements based on tiptap_content" do
    make_tiptap_content = lambda do |content|
      {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => content
            }
          ]
        }
      }
    end

    cover = create(:folio_file_image)
    reports = [create(:folio_file_document)]

    node = Dummy::Tiptap::Node::Card.new(title: "card",
                                         cover:,
                                         reports:)

    page = create(:folio_page, tiptap_content: nil)
    assert_equal 0, page.tiptap_placements.count

    page.update!(tiptap_content: make_tiptap_content.call([
      node.to_tiptap_node_hash,
    ]))
    assert_equal 2, page.tiptap_placements.count

    page.update!(tiptap_content: make_tiptap_content.call([
      node.to_tiptap_node_hash,
      node.to_tiptap_node_hash,
    ]))
    assert_equal 4, page.tiptap_placements.count

    page.update!(tiptap_content: make_tiptap_content.call([
      {
        "type" => "paragraph",
        "content" => [
          {
            "type" => "text",
            "text" => "Hello world"
          }
        ]
      }
    ]))
    assert_equal 0, page.tiptap_placements.count
  end

  private
    def dummy_tiptap_doc
      {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Hello world"
                }
              ]
            }
          ]
        }
      }
    end

    def xss_tiptap_doc
      {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [
              { "type" => "text", "text" => "<script>alert('XSS')</script>" },
              { "type" => "<script>alert('XSS')</script>", "text" => "<script>alert('XSS')</script>" },
              { "type" => "text", "text" => "<strong><img onload='alert(\"XSS\")'</strong>" },
              { "type" => "text", "text" => "<p>random HTML</p>" }
            ] }
          ]
        }
      }
    end

    def sanitized_tiptap_doc
      {
        Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
          "type" => "doc",
          "content" => [
            { "type" => "paragraph", "content" => [
              { "type" => "text", "text" => "alert('XSS')" },
              { "type" => "alert('XSS')", "text" => "alert('XSS')" },
              { "type" => "text", "text" => "" },
              { "type" => "text", "text" => "random HTML" }
            ] }
          ]
        }
      }
    end
end
