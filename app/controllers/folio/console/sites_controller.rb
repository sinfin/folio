# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Console::SitesController < Console::BaseController
    # before_action :find_site

    def update
      @site.update(site_params)
      respond_with @site, location: edit_console_site_path(@site)
    end

  private
    # def find_site
    #   @site = @site
    # end

    def site_params
      params.require(:site).permit(:title, :domain, :locale, :google_analytics_tracking_code, :facebook_pixel_code, locales: [])
    end
  end
end
