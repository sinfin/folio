# frozen_string_literal: true

Rails.application.config.folio_users_confirmable = false
Rails.application.config.folio_pages_audited = true
Rails.application.config.folio_pages_ancestry = !Rails.env.test?
Rails.application.config.folio_users_publicly_invitable = true # to make more test run
Rails.application.config.folio_shared_files_between_sites = true

Rails.application.config.folio_console_files_additional_html_api_url_lambda = -> (file) do
  if file.is_a?(Folio::File::Video)
    "/console/dummy/playground/additional_html_for_video_files_modal"
  end
end
