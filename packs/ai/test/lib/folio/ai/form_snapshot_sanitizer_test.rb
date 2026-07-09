# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::FormSnapshotSanitizerTest < ActiveSupport::TestCase
  test "normalizes form field names and removes framework metadata" do
    result = sanitize({
      "authenticity_token" => "secret",
      "_method" => "patch",
      "folio_page[id]" => "42",
      "folio_page[title]" => "<strong>Draft</strong> <a href=\"https://example.com/source\">source</a>",
      "folio_page[perex]" => "  Short perex.  ",
    })

    assert_equal "Draft source (https://example.com/source)", result["title"]
    assert_equal "Short perex.", result["perex"]
    assert_nil result["id"]
    assert_nil result["authenticity_token"]
    assert_nil result["_method"]
  end

  test "keeps nested atom-like text and url data" do
    result = sanitize({
      "folio_page[atoms_attributes][0][id]" => "42",
      "folio_page[atoms_attributes][0][data][title]" => "<em>Atom title</em>",
      "folio_page[atoms_attributes][0][data][url_json]" => {
        href: "https://example.com/atom",
        label: "Atom link",
        record_id: 123,
      }.to_json,
    })

    atom_data = result.dig("atoms_attributes", "0", "data")

    assert_equal "Atom title", atom_data["title"]
    assert_equal({ "label" => "Atom link", "href" => "https://example.com/atom" },
                 atom_data["url_json"])
    assert_nil result.dig("atoms_attributes", "0", "id")
  end

  test "extracts tiptap text and selected semantic metadata" do
    result = sanitize({
      "folio_page[tiptap_content]" => tiptap_content.to_json,
    })

    context = result.fetch("tiptap_content")

    assert_includes context["text"], "Intro linked source"
    assert_includes context["text"], "Card title Card text"
    assert_includes context["links"], {
      "label" => "linked source",
      "href" => "https://example.com/source",
    }
    assert_includes context["links"], {
      "label" => "Read more",
      "href" => "https://example.com/button",
    }
    assert_includes context["embeds"], {
      "type" => "instagram",
      "url" => "https://www.instagram.com/p/ABC123/",
    }
    assert_includes context["embeds"], {
      "urls" => ["https://www.youtube.com/embed/xyz"],
    }
    assert_includes context["attachments"], {
      "alt" => "Alt text",
      "description" => "Image description (https://example.com/image)",
    }
  end

  private
    def sanitize(snapshot)
      Folio::Ai::FormSnapshotSanitizer.call(record: Folio::Page.new,
                                            snapshot:)
    end

    def tiptap_content
      {
        "tiptap_content" => {
          "type" => "doc",
          "content" => [
            paragraph_with_link,
            embed_node("instagram" => "https://www.instagram.com/p/ABC123/"),
            embed_node("html" => "<iframe src=\"https://www.youtube.com/embed/xyz\"></iframe>"),
            card_node,
          ],
        },
      }
    end

    def paragraph_with_link
      {
        "type" => "paragraph",
        "content" => [
          { "type" => "text", "text" => "Intro " },
          {
            "type" => "text",
            "text" => "linked source",
            "marks" => [
              {
                "type" => "link",
                "attrs" => { "href" => "https://example.com/source" },
              },
            ],
          },
        ],
      }
    end

    def embed_node(data)
      embed_data = if data.key?("html")
        { "active" => true, "html" => data.fetch("html") }
      else
        type, url = data.first
        { "active" => true, "type" => type, "url" => url }
      end

      folio_tiptap_node("Dummy::Tiptap::Node::Embed",
                        "folio_embed_data" => embed_data)
    end

    def card_node
      folio_tiptap_node("Dummy::Tiptap::Node::Card",
                        "title" => "Card title",
                        "text" => "Card text",
                        "button_url_json" => {
                          "href" => "https://example.com/button",
                          "label" => "Read more",
                          "record_id" => 123,
                        }.to_json,
                        "cover_placement_attributes" => {
                          "file_id" => 123,
                          "alt" => "<strong>Alt</strong> text",
                          "description" => "<a href=\"https://example.com/image\">Image description</a>",
                        })
    end

    def folio_tiptap_node(class_name, data)
      {
        "type" => "folioTiptapNode",
        "attrs" => {
          "type" => class_name,
          "version" => 1,
          "data" => data,
        },
      }
    end
end
