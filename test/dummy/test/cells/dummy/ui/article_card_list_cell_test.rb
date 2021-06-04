# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ArticleCardListCellTest < Cell::TestCase
  test "show" do
    model = create_list(:dummy_blog_article, 1)
    html = cell("dummy/ui/article_card_list", model).(:show)
    assert html.has_css?(".d-ui-article-card-list")
  end
end
