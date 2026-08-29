# frozen_string_literal: true

class Dummy::Menu::Footer < Folio::Menu
  include Dummy::Menu::Base
  include Folio::Singleton

  def self.max_nesting_depth
    1
  end
end
