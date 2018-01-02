# frozen_string_literal: true

class Folio::Console::PositioningButtonsCell < FolioCell
  include FontAwesome::Rails::IconHelper

  def path
    url_for(action: :set_positions,
            only_path: true,
            format: :json,
            locale: nil)
  end
end
