# frozen_string_literal: true

class Folio::Console::Form::HeaderCell < Folio::ConsoleCell
  def translations
    cell('folio/console/pages/translations', model, as_pills: true)
  end

  def title
    model.try(:to_label) || model.try(:title) || model.class.model_name.human
  end
end
