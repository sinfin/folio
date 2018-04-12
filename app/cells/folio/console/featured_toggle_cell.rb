# frozen_string_literal: true

class Folio::Console::FeaturedToggleCell < Folio::Console::BooleanToggleCell
  ATTRIBUTE = :featured
  ICON_ON = 'star'
  ICON_OFF = 'star-o'
end
