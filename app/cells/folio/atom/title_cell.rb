# frozen_string_literal: true

class Folio::Atom::TitleCell < Folio::ApplicationCell
  include Folio::CstypoHelper

  def show
    render if model.title.present?
  end
end
