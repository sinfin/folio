# frozen_string_literal: true

class Folio::Console::File::AudiosController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Audio"

  private
    def file_params
      super.merge(
        params.require(:file).permit(artwork_cover_placement_attributes: [:id, :file_id, :_destroy])
      )
    end
end
