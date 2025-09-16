# frozen_string_literal: true

class Folio::Console::MediaSourcesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::MediaSource"

  private
    def media_source_params
      if Rails.application.config.folio_shared_files_between_sites
        params.require(:media_source)
              .permit(:title,
                      :licence,
                      :copyright_text,
                      :max_usage_count,
                      media_source_site_links_attributes: %w[id _destroy site_id])
      else
        params.require(:media_source)
              .permit(:title,
                      :licence,
                      :copyright_text,
                      :max_usage_count)
      end
    end
end
