# frozen_string_literal: true

class Folio::Console::NestedModelControlsCell < FolioCell
  include Cocoon::ViewHelpers

  def f
    model
  end

  def handle_position?
    options[:only].blank? || options[:only] == :position
  end

  def handle_destroy?
    options[:only].blank? || options[:only] == :destroy
  end
end
