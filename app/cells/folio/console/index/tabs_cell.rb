# frozen_string_literal: true

class Folio::Console::Index::TabsCell < Folio::ConsoleCell
  include Folio::ActiveClass

  def show
    render if model.present?
  end
end
