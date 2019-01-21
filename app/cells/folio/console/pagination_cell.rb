# frozen_string_literal: true

class Folio::Console::PaginationCell < Folio::ConsoleCell
  include Pagy::Frontend

  def show
    render if model.present? && model.pages > 1
  end
end
