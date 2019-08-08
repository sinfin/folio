# frozen_string_literal: true

class Folio::Console::SitesController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Site'

  before_action :find_site

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
                                   :email_from,
                                   :system_email,
                                   :system_email_copy,
                                   :address,
                                   *@site.class.additional_params,
                                   *file_placements_strong_params,
                                   locales: [],
                                   social_links: Folio::Site.social_link_sites)
    end

    def find_site
      @site = Folio::Site.instance
    end
end
