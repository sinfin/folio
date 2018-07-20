# frozen_string_literal: true

class Folio::Console::AhoyEventsCell < FolioCell
  def icon_class(event_name)
    case event_name
    when '$view'
      'fa-search'
    when '$click'
      'fa-hand-o-up'
    when '$change'
      'fa-bold'
    when '$submit'
      'fa-location-arrow'
    end
  end
end
