# frozen_string_literal: true

class Dummy::Blog::Articles::CardsComponent < ApplicationComponent
  def initialize(articles:, size: :m, size_of_first: nil)
    @articles = articles
    @size = size
    @size_of_first = size_of_first
  end

  def ui_cards_component
    Dummy::Ui::CardsComponent.new(class_name: "d-blog-articles-cards",
                                  cards:)
  end

  def cards
    @articles.each_with_index.map do |article, index|
      Dummy::Blog::Articles::CardComponent.ui_card_component_hash_from_article(article:,
                                                                               size: (index.zero? && @size_of_first) ? @size_of_first : @size,
                                                                               controller:)
    end
  end
end
