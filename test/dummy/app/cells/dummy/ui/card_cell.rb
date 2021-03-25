# frozen_string_literal: true

class Dummy::Ui::CardCell < ApplicationCell
  THUMB_SIZE_LARGE = "645x430#"
  THUMB_SIZE_MEDIUM = "420x280#"
  THUMB_SIZE_SMALL = "83x79#"

  def size_class_name
    if model[:medium]
      "d-ui-card--size-medium"
    elsif model[:small]
      "d-ui-card--size-small"
    else
      "d-ui-card--size-large"
    end
  end

  def image_class_name
    if model[:cover_placement].present?
      "d-ui-card--image-present"
    else
      "d-ui-card--image-blank"
    end
  end

  def title_tag
    tag = { tag: :h2, class: "d-ui-card__title" }

    if model[:medium]
      tag[:tag] = :h3
    elsif model[:small]
      tag[:tag] = :p
    end

    tag
  end

  def thumb_size
    if model[:medium]
      THUMB_SIZE_MEDIUM
    elsif model[:small]
      THUMB_SIZE_SMALL
    else
      THUMB_SIZE_LARGE
    end
  end

  def content_content_class_name
    if model[:medium]
      "text-line-clamp-3"
    elsif model[:small]
      "small"
    end
  end
end
