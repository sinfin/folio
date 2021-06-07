# frozen_string_literal: true

class Dummy::Ui::ArticleCardCell < ApplicationCell
  THUMB_SIZE = "420x420#"

  def size_class_name
    if medium?
      "d-ui-article-card--size-medium"
    elsif small?
      "d-ui-article-card--size-small"
    else
      "d-ui-article-card--size-large"
    end
  end

  def image_class_name
    if model[:cover_placement].present?
      "d-ui-article-card--image-present"
    else
      "d-ui-article-card--image-blank"
    end
  end

  def title_tag
    tag = { tag: :h2, class: "d-ui-article-card__title" }

    if medium?
      tag[:tag] = :h3
    elsif small?
      tag[:tag] = :div
      tag[:class] += " font-size-lg"
    end

    tag
  end

  def has_button?
    !small? && model[:button_label].present?
  end

  def truncate(str)
    ActionController::Base.helpers.truncate(str)
  end

  def large?
    !medium? && !small?
  end

  def medium?
    model[:medium] || options[:medium]
  end

  def small?
    model[:small] || options[:small]
  end
end
