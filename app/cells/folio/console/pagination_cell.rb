# frozen_string_literal: true

class Folio::Console::PaginationCell < Folio::ConsoleCell
  include Pagy::Frontend

  def show
    render if model.present? && model.count > 0
  end

  def link
    @link ||= pagy_anchor(model)
  end

  def icon(code)
    folio_icon(code, class: "f-c-pagination__ico")
  end
end
