# frozen_string_literal: true

class Dummy::Mailer::CardComponent < ApplicationComponent
  THUMB_SIZE = "250x300"

  def initialize(folio_image: nil, title: nil, button_label: nil, button_href: nil)
    @folio_image = folio_image
    @title = title
    @button_label = button_label
    @button_href = button_href
  end
end
