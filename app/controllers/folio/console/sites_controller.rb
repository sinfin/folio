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
      ary = %i[
        title
        description
        locale
        google_analytics_tracking_code
        google_analytics_tracking_code_v4
        facebook_pixel_code
        phone
        email
        email_from
        system_email
        system_email_copy
        header_message_published
        header_message_published_from
        header_message_published_until
        header_message
        address
        copyright_info_source
      ]

      ary << :domain if Rails.application.config.folio_site_is_a_singleton

      params.require(:site)
            .permit(*ary,
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
