# frozen_string_literal: true

class Folio::Console::Ui::DropdownComponent < Folio::Console::ApplicationComponent
  def initialize(links:, menu_align: :left)
    @links = links
    @menu_align = menu_align
  end
end
