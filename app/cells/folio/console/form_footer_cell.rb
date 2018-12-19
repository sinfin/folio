# frozen_string_literal: true

class Folio::Console::FormFooterCell < Folio::ConsoleCell
  def class_name
    'folio-console-form-footer--static' if options[:static]
  end
end
