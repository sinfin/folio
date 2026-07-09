# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::ComponentIdsTest < ActiveSupport::TestCase
  test "builds default input ids from form object names and field keys" do
    assert_equal "folio_page_title",
                 Folio::Ai::ComponentIds.default_input_id(object_name: "folio_page",
                                                          field_key: "title")

    assert_equal "article_variants_attributes_0_meta_title",
                 Folio::Ai::ComponentIds.default_input_id(object_name: "article[variants_attributes][0]",
                                                          field_key: "meta_title")
  end

  test "builds text suggestion component ids from input ids" do
    assert_equal "folio_ai_text_suggestions_custom_meta_title",
                 Folio::Ai::ComponentIds.text_suggestions_component_id(input_id: "custom[meta title]")
  end

  test "builds default text suggestion component ids" do
    assert_equal "folio_ai_text_suggestions_article_variants_attributes_0_meta_title",
                 Folio::Ai::ComponentIds.default_text_suggestions_component_id(object_name: "article[variants_attributes][0]",
                                                                               field_key: "meta_title")
  end
end
