# frozen_string_literal: true

class NestableMenu < Folio::Menu
  def self.max_nesting_depth
    3
  end
end
