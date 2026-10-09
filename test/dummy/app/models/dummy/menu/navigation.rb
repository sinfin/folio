# frozen_string_literal: true

class Dummy::Menu::Navigation < Folio::Menu
  include Dummy::Menu::Base

  def self.max_nesting_depth
    1
  end
end
