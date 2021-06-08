# frozen_string_literal: true

class Dummy::Atom::Blog::Articles::FeaturedCell < ApplicationCell
  def articles
    klass.published
         .featured
         .ordered
         .by_locale(I18n.locale)
         .includes(:published_topics, cover_placement: :file)
         .limit(2)
  end

  def klass
    Dummy::Blog::Article
  end
end
