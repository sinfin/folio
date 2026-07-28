# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::FormSnapshotSanitizerTest < ActiveSupport::TestCase
  SnapshotColumn = Struct.new(:type)

  class SnapshotRecord
    COLUMNS_HASH = {
      "title" => SnapshotColumn.new(:string),
      "body" => SnapshotColumn.new(:text),
      "settings" => SnapshotColumn.new(:jsonb),
      "atoms_data_for_search" => SnapshotColumn.new(:text),
      "published" => SnapshotColumn.new(:boolean),
      "site_id" => SnapshotColumn.new(:integer),
      "slug" => SnapshotColumn.new(:string),
      "api_key" => SnapshotColumn.new(:string),
    }.freeze

    def self.model_name
      ActiveModel::Name.new(self, nil, "SnapshotRecord")
    end

    def self.table_name
      "snapshot_records"
    end

    def self.columns_hash
      COLUMNS_HASH
    end
  end

  test "normalizes form field names and removes framework metadata" do
    result = sanitize({
      "authenticity_token" => "secret",
      "_method" => "patch",
      "folio_page[id]" => "42",
      "folio_page[title]" => "<strong>Draft</strong> <a href=\"https://example.com/source\">source</a>",
      "folio_page[perex]" => "  Short perex.  ",
      "folio_page[slug]" => "draft-slug",
      "folio_page[preview_token]" => "secret-token",
      "folio_page[api_key]" => "secret-api-key",
      "folio_page[password]" => "secret-password",
    })

    assert_equal "Draft source (https://example.com/source)", result["title"]
    assert_equal "Short perex.", result["perex"]
    assert_nil result["id"]
    assert_nil result["authenticity_token"]
    assert_nil result["_method"]
    assert_nil result["slug"]
    assert_nil result["preview_token"]
    assert_nil result["api_key"]
    assert_nil result["password"]
  end

  test "keeps safe record columns and drops unsafe form fields" do
    result = sanitize({
      "snapshot_record[title]" => "Column title",
      "snapshot_record[body]" => "<b>Body</b>",
      "snapshot_record[settings]" => {
        summary: "<em>JSON</em>",
        owner_id: 123,
        api_key: "nested-secret",
      }.to_json,
      "snapshot_record[atoms_data_for_search]" => "Cached body text",
      "snapshot_record[published]" => "1",
      "snapshot_record[site_id]" => "1",
      "snapshot_record[slug]" => "private-slug",
      "snapshot_record[api_key]" => "root-secret",
    }, record: SnapshotRecord.new)

    assert_equal "Column title", result["title"]
    assert_equal "Body", result["body"]
    assert_equal({ "summary" => "JSON" }, result["settings"])
    assert_nil result["atoms_data_for_search"]
    assert_nil result["published"]
    assert_nil result["site_id"]
    assert_nil result["slug"]
    assert_nil result["api_key"]
  end

  test "keeps registered ai fields outside record columns" do
    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [:custom_context])

    result = sanitize({
      "folio_page[custom_context]" => "<strong>Registered</strong> context",
      "folio_page[unregistered_context]" => "Dropped context",
    })

    assert_equal "Registered context", result["custom_context"]
    assert_nil result["unregistered_context"]
  ensure
    Folio::Ai.reset_registry!
  end

  test "allows record override to replace context roots" do
    record = SnapshotRecord.new
    record.define_singleton_method(:folio_ai_form_snapshot_context_keys) do |default_keys:|
      default_keys.without("title") + ["custom_context"]
    end

    result = sanitize({
      "snapshot_record[title]" => "Dropped title",
      "snapshot_record[body]" => "Body kept by default roots",
      "snapshot_record[custom_context]" => "<em>Custom</em>",
    }, record:)

    assert_nil result["title"]
    assert_equal "Body kept by default roots", result["body"]
    assert_equal "Custom", result["custom_context"]
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

  test "drops nested records marked for destruction" do
    result = sanitize({
      "folio_page[atoms_attributes][0][_destroy]" => "1",
      "folio_page[atoms_attributes][0][data][title]" => "Destroyed atom",
      "folio_page[atoms_attributes][1][data][title]" => "Kept atom",
    })

    assert_nil result.dig("atoms_attributes", "0")
    assert_equal "Kept atom", result.dig("atoms_attributes", "1", "data", "title")
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
    def sanitize(snapshot, record: Folio::Page.new)
      Folio::Ai::FormSnapshotSanitizer.call(record:,
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
