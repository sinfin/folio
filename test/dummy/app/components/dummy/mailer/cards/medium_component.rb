# frozen_string_literal: true

class Dummy::Mailer::Cards::MediumComponent < ApplicationComponent
  THUMB_SIZE = "296x320#"

  def initialize(folio_image: nil, title: nil, button_label: nil, button_href: nil, href: nil)
    @folio_image = folio_image
    @title = title
    @button_label = button_label
    @button_href = button_href
    @href = href
  end

  def link_with_fallback_tag
    base_class = "d-mailer-cards-medium__link"

    if @href.present?
      { tag: :a, href: @href, class: base_class, rel: "noopener", target: "_blank" }
    else
      {}
    end
  end
end
