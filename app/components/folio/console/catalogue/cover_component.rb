# frozen_string_literal: true

class Folio::Console::Catalogue::CoverComponent < Folio::Console::ApplicationComponent
  def initialize(file:, href: false, lightbox: true)
    @file = file
    @href = href
    @lightbox = lightbox
  end
end
