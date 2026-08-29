# frozen_string_literal: true

class Dummy::Menu::Stylable < Folio::Menu
  def self.max_nesting_depth
    2
  end

  def self.styles
    %w[red blue]
  end
end
