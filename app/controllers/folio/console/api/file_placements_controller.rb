# frozen_string_literal: true

class Folio::Console::Api::FilePlacementsController < Folio::Console::Api::BaseController
  def index
    file = Folio::File.find(params[:file_id])
    authorize!(:read, file)

    pagination, records = pagy(file.file_placements, items: 20)

    if file.file_placements_size != pagination.count
      file.update_column(:file_placements_size, pagination.count)
    end

    render_records(records,
                   Folio::Console::FilePlacementSerializer,
                   meta: meta_from_pagy(pagination))
  end
end
