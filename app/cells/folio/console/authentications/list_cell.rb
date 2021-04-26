# frozen_string_literal: true

class Folio::Console::Authentications::ListCell < Folio::ConsoleCell
  def authentications
    @authentications ||= model && model.authentications.group_by(&:provider)
  end
end
