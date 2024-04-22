# frozen_string_literal: true

class Dummy::Mailer::Cards::ExtraSmallComponent < ApplicationComponent
  THUMB_SIZE = "80x80#"

  def initialize(card:, even: false)
    @card = card
    @even = even
  end

  def render?
    @card.present?
  end

  def link_with_fallback_tag
    base_class = "d-mailer-cards-extra-small__title"

    if @card[:href].present?
      { tag: :a, href: @card[:href], class: base_class, rel: "noopener", target: "_blank" }
    else
      { class: base_class }
    end
  end

  def parent_class
    if @even
      "d-mailer-cards-extra-small--even"
    else
      "d-mailer-cards-extra-small--odd"
    end
  end

  def content_wrapper_class
    if @card[:image].present?
      "d-mailer-cards-extra-small__content-wrapper--with-image"
    else
      "d-mailer-cards-extra-small__content-wrapper--full"
    end
  end
end
