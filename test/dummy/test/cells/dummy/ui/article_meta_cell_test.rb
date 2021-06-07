# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ArticleMetaCellTest < Cell::TestCase
  test "show" do
    model = create(:dummy_blog_article).to_ui_article_card_model
    html = cell("dummy/ui/article_meta", model).(:show)
    assert html.has_css?(".d-ui-article-meta")
  end
end
