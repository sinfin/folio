# frozen_string_literal: true

require "test_helper"

class Folio::Ai::CurrentFormSnapshotTest < ActiveSupport::TestCase
  test "keeps whitelisted editorial fields and drops undeclared fields" do
    snapshot = {
      "folio_page[title]" => "Draft title",
      "folio_page[perex]" => "Draft perex",
      "folio_page[slug]" => "private-slug",
      "folio_page[api_key]" => "secret",
      "authenticity_token" => "token",
      "commit" => "Save",
      "folio_page[topic_article_links_attributes][0][dummy_blog_topic_id]" => "1",
    }

    result = filtered_snapshot(snapshot)

    assert_equal "Draft title", result["folio_page[title]"]
    assert_equal "Draft perex", result["folio_page[perex]"]
    assert_not_includes result, "folio_page[slug]"
    assert_not_includes result, "folio_page[api_key]"
    assert_not_includes result, "authenticity_token"
    assert_not_includes result, "commit"
    assert_not_includes result, "folio_page[topic_article_links_attributes][0][dummy_blog_topic_id]"
  end

  test "uses configured editorial field roots" do
    snapshot = {
      "folio_page[title]" => "Draft title",
      "folio_page[summary]" => "Draft summary",
    }

    with_ai_config(current_form_snapshot_field_roots: %i[summary]) do
      result = filtered_snapshot(snapshot)

      assert_equal "Draft summary", result["folio_page[summary]"]
      assert_not_includes result, "folio_page[title]"
    end
  end

  test "converts all configured tiptap fields to plain text" do
    snapshot = {
      "folio_page[tiptap_content]" => tiptap_text_content("Main text").to_json,
      "folio_page[sidebar_tiptap_content]" => tiptap_text_content("Sidebar text").to_json,
    }

    Folio::Page.stub(:folio_tiptap_fields, %w[tiptap_content sidebar_tiptap_content]) do
      result = filtered_snapshot(snapshot)

      assert_equal "Main text", result["folio_page[tiptap_content]"]
      assert_equal "Sidebar text", result["folio_page[sidebar_tiptap_content]"]
    end
  end

  test "keeps atom data leaves and drops atom metadata" do
    snapshot = {
      "folio_page[atoms_attributes][0][data][content]" => "Atom body",
      "folio_page[atoms_attributes][0][data][label]" => "Atom label",
      "folio_page[atoms_attributes][0][id]" => "10",
      "folio_page[atoms_attributes][0][type]" => "Dummy::Atom::Contents::Text",
      "folio_page[atoms_attributes][0][position]" => "1",
    }

    result = filtered_snapshot(snapshot)

    assert_equal "Atom body", result["folio_page[atoms_attributes][0][data][content]"]
    assert_equal "Atom label", result["folio_page[atoms_attributes][0][data][label]"]
    assert_not_includes result, "folio_page[atoms_attributes][0][id]"
    assert_not_includes result, "folio_page[atoms_attributes][0][type]"
    assert_not_includes result, "folio_page[atoms_attributes][0][position]"
  end

  test "keeps localized atom data leaves from record atom keys" do
    snapshot = {
      "folio_page[cs_atoms_attributes][0][data][content]" => "Cesky atom",
      "folio_page[en_atoms_attributes][0][data][content]" => "English atom",
      "folio_page[atoms_attributes][0][data][content]" => "Default atom",
    }

    Folio::Page.stub(:atom_keys, %i[cs_atoms en_atoms]) do
      result = filtered_snapshot(snapshot)

      assert_equal "Cesky atom", result["folio_page[cs_atoms_attributes][0][data][content]"]
      assert_equal "English atom", result["folio_page[en_atoms_attributes][0][data][content]"]
      assert_not_includes result, "folio_page[atoms_attributes][0][data][content]"
    end
  end

  test "keeps file placement text leaves and drops placement metadata" do
    snapshot = {
      "folio_page[image_or_embed_placements_attributes][0][title]" => "Image title",
      "folio_page[image_or_embed_placements_attributes][0][alt]" => "Image alt",
      "folio_page[image_or_embed_placements_attributes][0][description]" => "Image description",
      "folio_page[image_or_embed_placements_attributes][0][folio_embed_data]" => "{\"active\":true}",
      "folio_page[image_or_embed_placements_attributes][0][id]" => "20",
      "folio_page[image_or_embed_placements_attributes][0][file_id]" => "30",
      "folio_page[cover_placement_attributes][title]" => "Cover title",
    }

    result = filtered_snapshot(snapshot)

    assert_equal "Image title", result["folio_page[image_or_embed_placements_attributes][0][title]"]
    assert_equal "Image alt", result["folio_page[image_or_embed_placements_attributes][0][alt]"]
    assert_equal "Image description", result["folio_page[image_or_embed_placements_attributes][0][description]"]
    assert_equal "{\"active\":true}", result["folio_page[image_or_embed_placements_attributes][0][folio_embed_data]"]
    assert_equal "Cover title", result["folio_page[cover_placement_attributes][title]"]
    assert_not_includes result, "folio_page[image_or_embed_placements_attributes][0][id]"
    assert_not_includes result, "folio_page[image_or_embed_placements_attributes][0][file_id]"
  end

  test "uses configured file placement text keys" do
    snapshot = {
      "folio_page[image_or_embed_placements_attributes][0][title]" => "Image title",
      "folio_page[image_or_embed_placements_attributes][0][caption]" => "Image caption",
    }

    with_ai_config(current_form_snapshot_file_placement_text_keys: %i[caption]) do
      result = filtered_snapshot(snapshot)

      assert_equal "Image caption", result["folio_page[image_or_embed_placements_attributes][0][caption]"]
      assert_not_includes result, "folio_page[image_or_embed_placements_attributes][0][title]"
    end
  end

  test "keeps file placement text leaves inside atoms" do
    snapshot = {
      "folio_page[atoms_attributes][0][cover_placement_attributes][title]" => "Atom cover",
      "folio_page[atoms_attributes][0][cover_placement_attributes][file_id]" => "1",
      "folio_page[atoms_attributes][0][image_placements_attributes][0][description]" => "Atom image description",
      "folio_page[atoms_attributes][0][image_placements_attributes][0][id]" => "2",
    }

    result = filtered_snapshot(snapshot)

    assert_equal "Atom cover", result["folio_page[atoms_attributes][0][cover_placement_attributes][title]"]
    assert_equal "Atom image description",
                 result["folio_page[atoms_attributes][0][image_placements_attributes][0][description]"]
    assert_not_includes result, "folio_page[atoms_attributes][0][cover_placement_attributes][file_id]"
    assert_not_includes result, "folio_page[atoms_attributes][0][image_placements_attributes][0][id]"
  end

  test "omits nested records marked for destruction" do
    snapshot = {
      "folio_page[atoms_attributes][0][_destroy]" => "1",
      "folio_page[atoms_attributes][0][data][content]" => "Destroyed atom",
      "folio_page[atoms_attributes][1][_destroy]" => "0",
      "folio_page[atoms_attributes][1][data][content]" => "Kept atom",
      "folio_page[atoms_attributes][2][cover_placement_attributes][_destroy]" => true,
      "folio_page[atoms_attributes][2][cover_placement_attributes][title]" => "Destroyed atom cover",
      "folio_page[atoms_attributes][2][data][content]" => "Atom remains",
      "folio_page[image_or_embed_placements_attributes][0][_destroy]" => "true",
      "folio_page[image_or_embed_placements_attributes][0][title]" => "Destroyed image",
      "folio_page[image_or_embed_placements_attributes][1][_destroy]" => "0",
      "folio_page[image_or_embed_placements_attributes][1][title]" => "Kept image",
    }

    result = filtered_snapshot(snapshot)

    assert_not_includes result, "folio_page[atoms_attributes][0][_destroy]"
    assert_not_includes result, "folio_page[atoms_attributes][0][data][content]"
    assert_not_includes result, "folio_page[atoms_attributes][1][_destroy]"
    assert_equal "Kept atom", result["folio_page[atoms_attributes][1][data][content]"]
    assert_not_includes result, "folio_page[atoms_attributes][2][cover_placement_attributes][_destroy]"
    assert_not_includes result, "folio_page[atoms_attributes][2][cover_placement_attributes][title]"
    assert_equal "Atom remains", result["folio_page[atoms_attributes][2][data][content]"]
    assert_not_includes result, "folio_page[image_or_embed_placements_attributes][0][title]"
    assert_not_includes result, "folio_page[image_or_embed_placements_attributes][1][_destroy]"
    assert_equal "Kept image", result["folio_page[image_or_embed_placements_attributes][1][title]"]
  end

  test "keeps arrays of allowed scalar values" do
    snapshot = {
      "folio_page[title]" => ["First", "Second", { "bad" => "value" }],
    }

    assert_equal ["First", "Second"], filtered_snapshot(snapshot)["folio_page[title]"]
  end

  test "returns empty hash for non hash snapshots" do
    [
      [],
      ["bad"],
      "bad",
      1,
    ].each do |snapshot|
      assert_equal({}, filtered_snapshot(snapshot))
    end
  end

  private
    def filtered_snapshot(snapshot, record_class: Folio::Page)
      Folio::Ai::CurrentFormSnapshot.call(snapshot:,
                                          record_class:)
    end
end
