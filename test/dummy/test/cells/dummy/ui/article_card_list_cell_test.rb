# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ArticleCardListCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/article_card_list", nil).(:show)
    assert html.has_css?(".d-ui-article-card-list")
  end
end
