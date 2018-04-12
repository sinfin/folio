# frozen_string_literal: true

class Folio::Console::PublishedToggleCell < Folio::Console::BooleanToggleCell
  ATTRIBUTE = :published
  ICON_ON = 'toggle-on'
  ICON_OFF = 'toggle-off'
end
