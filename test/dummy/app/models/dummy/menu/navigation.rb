# frozen_string_literal: true

class Dummy::Menu::Navigation < Folio::Menu
  def self.max_nesting_depth
    2
  end
end
