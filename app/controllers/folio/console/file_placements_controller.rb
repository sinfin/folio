# frozen_string_literal: true

class Folio::Console::FilePlacementsController < Folio::Console::BaseController
  def destroy
    placement = Folio::FilePlacement::Base.find(params[:id])
    authorize!(:destroy, placement.file)

    # only orphaned usage records may be removed from here - live content is
    # unlinked by editing the owning record
    raise ActiveRecord::RecordNotFound if placement.placement.present?

    placement.destroy!

    redirect_back fallback_location: url_for([:console, placement.file]),
                  flash: { success: t("folio.console.file_placements.destroyed") }
  end
end
