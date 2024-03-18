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
    base_class = "d-mailer-cards-extra-small__link"

    if @card[:href].present?
      { tag: :a, href: @href, class: base_class, rel: "noopener", target: "_blank" }
    else
      {}
    end
  end
end
