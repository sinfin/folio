# frozen_string_literal: true

class Folio::Console::AtomPreviewsController < Folio::Console::BaseController
  def show
    data = nil
    render plain: cell('folio/console/atom_previews', data).show,
           layout: false
  end
end
