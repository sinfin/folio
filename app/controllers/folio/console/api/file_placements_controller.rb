# frozen_string_literal: true

class Folio::Console::Api::FilePlacementsController < Folio::Console::Api::BaseController
  def index
    file = Folio::File.find(params[:file_id])
    pagination, records = pagy(file.file_placements, items: 20)

    render_records(records,
                   Folio::Console::FilePlacementSerializer,
                   meta: meta_from_pagy(pagination))
  end
end
