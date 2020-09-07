# frozen_string_literal: true

class Folio::Console::SitesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Site"

  before_action :find_site
  before_action :add_site_breadcrumb

  def update
    @site.update(site_params)
    respond_with @site, location: edit_console_site_path
  end

  def clear_cache
    Rails.cache.clear
    redirect_to edit_console_site_path, flash: { notice: t(".success") }
  end

  private
    def site_params
      params.require(:site)
            .permit(:title,
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
      @site = current_site
    end

    def add_site_breadcrumb
      add_breadcrumb(@klass.model_name.human(count: 2))
    end
end
