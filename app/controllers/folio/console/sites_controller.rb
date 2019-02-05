# frozen_string_literal: true

class Folio::Console::SitesController < Folio::Console::BaseController
  def index
    redirect_to console_root_path
  end

  def edit
  end

  def update
    @site.update(site_params)
    respond_with @site, location: edit_console_site_path
  end

  private

    def site_params
      params.require(:site).permit(:title,
                                   :description,
                                   :domain,
                                   :locale,
                                   :google_analytics_tracking_code,
                                   :facebook_pixel_code,
                                   :phone,
                                   :email,
                                   :address,
                                   *@site.class.additional_params,
                                   *file_placements_strong_params,
                                   locales: [],
                                   social_links: Folio::Site.social_link_sites)
    end
end
