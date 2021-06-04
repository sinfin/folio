# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ArticleCardCellTest < Cell::TestCase
  test "show" do
    model = create(:dummy_blog_article)
    html = cell("dummy/ui/article_card", model).(:show)
    assert html.has_css?(".d-ui-article-card")
  end
end
