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
  end
end
