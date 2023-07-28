# frozen_string_literal: true

class Folio::Console::Ui::ButtonsCell < Folio::ConsoleCell
  class_name "f-c-ui-buttons", :vertical

  def show
    render if model.present?
  end
end
