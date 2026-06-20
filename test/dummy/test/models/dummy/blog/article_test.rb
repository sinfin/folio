# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::ArticleTest < ActiveSupport::TestCase
  test "uses ai pack extension hooks" do
    article = create(:dummy_blog_article,
                     title: "Article title",
                     perex: "Article perex",
                     meta_title: "Meta title",
                     meta_description: "Meta description")

    assert_kind_of Dummy::Ai::DemoProviderAdapter, article.folio_ai_provider_adapter
    assert article.folio_ai_suggestions_eligible?(field_key: "title",
                                                  current_form_snapshot: {})

    context = article.folio_ai_context(field_key: "title",
                                       current_form_snapshot: { "title" => "Draft title" })

    assert_equal "Article title", context[:title]
    assert_equal "Article perex", context[:perex]
    assert_equal "Meta title", context[:meta_title]
    assert_equal "Meta description", context[:meta_description]
    assert_equal({ "title" => "Draft title" }, context[:current_form_snapshot])
  end
end
