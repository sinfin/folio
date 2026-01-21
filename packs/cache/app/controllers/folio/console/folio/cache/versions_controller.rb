# frozen_string_literal: true

class Folio::Console::Folio::Cache::VersionsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Cache::Version"

  def invalidate
    @version = Folio::Cache::Version.find(params[:id])
    Folio::Cache::Invalidator.invalidate!(site_id: @version.site_id, keys: [@version.key])
    flash[:notice] = t(".flash")
    redirect_to url_for([:console, Folio::Cache::Version])
  end
end
