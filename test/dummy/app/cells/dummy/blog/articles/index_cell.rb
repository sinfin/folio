# frozen_string_literal: true

class Dummy::Blog::Articles::IndexCell < ApplicationCell
  def show
    if model.present?
      if active_pagy?
        @small_articles = model
      else
        @main_article = model[0]
        @secondary_articles = model[1..2]
        @small_articles = model[3..-1]
      end

      render
    end
  end

  def topics
    options[:topics]
  end

  def active_pagy?
    @active_pagy ||= options[:pagy] && options[:pagy].page != 1
  end
end
