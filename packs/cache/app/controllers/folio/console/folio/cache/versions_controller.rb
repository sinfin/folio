# frozen_string_literal: true

class Folio::Console::Folio::Cache::VersionsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Cache::Version"

  def invalidate
    @version = Folio::Cache::Version.find(params[:id])
    Folio::Cache::Invalidator.invalidate!(site_id: @version.site_id, keys: [@version.key])
    flash[:notice] = t(".flash")
    redirect_to url_for([:console, Folio::Cache::Version])
  end

  def invalidate_all
    site = Folio::Current.site
    keys = Folio::Cache::Version.where(site_id: site.id).pluck(:key)

    if keys.any?
      Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys:)
      flash[:notice] = t(".invalidate_all_flash")
    else
      flash[:notice] = t(".invalidate_all_flash_empty")
    end

    redirect_to url_for([:console, Folio::Cache::Version])
  end

  def clear_rails_cache
    Rails.cache.clear
    flash[:notice] = t(".clear_rails_cache_flash")
    redirect_to url_for([:console, Folio::Cache::Version])
  end
end
