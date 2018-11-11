# frozen_string_literal: true

class Folio::Console::FormFooterCell < FolioCell
  def class_name
    'folio-console-form-footer--static' if options[:static]
  end
end
