# frozen_string_literal: true

class Dummy::Menu::Header < Folio::Menu
  include Folio::Singleton

  def self.max_nesting_depth
    2
  end
end
