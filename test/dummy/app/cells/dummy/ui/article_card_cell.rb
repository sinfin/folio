# frozen_string_literal: true

class Dummy::Ui::ArticleCardCell < ApplicationCell
  THUMB_SIZE_LARGE = "420x420#"
  THUMB_SIZE_MEDIUM = "213x213#"
  THUMB_SIZE_SMALL = "83x79#"

  def size_class_name
    if model[:medium] || options[:medium]
      "d-ui-article-card--size-medium"
    elsif model[:small] || options[:small]
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

    if model[:medium] || options[:medium]
      tag[:tag] = :h3
    elsif model[:small] || options[:small]
      tag[:tag] = :a
      tag[:href] = model[:href]
    end

    tag
  end

  def thumb_size
    if model[:medium] || options[:medium]
      THUMB_SIZE_MEDIUM
    elsif model[:small] || options[:small]
      THUMB_SIZE_SMALL
    else
      THUMB_SIZE_LARGE
    end
  end

  def content_content_class_name
    if model[:medium] || options[:medium]
      "text-line-clamp-3"
    elsif model[:small] || options[:small]
      "small"
    end
  end
end
