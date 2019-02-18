# frozen_string_literal: true

class Folio::Atom::TitleCell < Folio::ApplicationCell
  def show
    render if model.title.present?
  end
end
