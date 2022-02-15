# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end

    config.assets.paths << self.root.join("app/cells")
    config.assets.paths << self.root.join("vendor/assets/javascripts")
    config.assets.paths << self.root.join("vendor/assets/bower_components")
    config.assets.precompile += %w[
      folio/console/base.css
      folio/console/base.js
      folio/console/react/main.js
      folio/console/react/main.css
    ]

    config.folio_dragonfly_keep_png = true
    config.folio_public_page_title_reversed = false
    config.folio_using_traco = false
    config.folio_pages_audited = false
    config.folio_pages_translations = false
    config.folio_pages_ancestry = false
    config.folio_pages_perex_richtext = false
    config.folio_console_locale = :cs
    config.folio_console_dashboard_redirect = :console_pages_path
    config.folio_console_sidebar_link_class_names = nil
    config.folio_console_sidebar_prepended_link_class_names = []
    config.folio_console_sidebar_appended_link_class_names = []
    config.folio_console_sidebar_runner_up_link_class_names = []
    config.folio_console_sidebar_skip_link_class_names = []
    config.folio_server_names = []
    config.folio_image_spacer_background_fallback = nil
    config.folio_show_transportable_frontend = false
    config.folio_modal_cell_name = nil
    config.folio_use_og_image = true
    config.folio_aasm_mailer_config = {}

    config.folio_direct_s3_upload_class_names = %w[
      Folio::File
      Folio::PrivateAttachment
    ]

    config.folio_users = false
    config.folio_users_require_phone = false
    config.folio_users_confirmable = false
    config.folio_users_registerable = true
    config.folio_users_use_address = true
    config.folio_users_omniauth_providers = %i[facebook google_oauth2 twitter]
    config.folio_users_after_ajax_sign_up_redirect = false
    config.folio_users_after_sign_in_path = :root_path
    config.folio_users_after_sign_up_path = :root_path
    config.folio_users_after_update_path_for = :root_path
    config.folio_users_after_sign_out_path = :new_user_session_path
    config.folio_users_after_accept_path = :root_path
    config.folio_users_signed_in_root_path = :root_path

    config.folio_console_ability_lambda = -> (ability, account) { }

    config.folio_cookie_consent_configuration = {
      enabled: true,
      cookies: {
        necessary: [
          :cc_cookie,
          :session_id,
          :s_for_log,
          :u_for_log,
        ],
        analytics: [
          :_ga,
          :_gid,
          :_ga_container_id,
          :_gac_gb_container_id,
        ]
      }
    }

    initializer :append_migrations do |app|
      unless app.root.to_s.include? root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    begin
      initializer :deprecations do |app|
        deprecations = []

        begin
          if ActiveRecord::Base.connection.exec_query("SELECT column_name FROM information_schema.columns WHERE table_name = 'folio_files' AND column_name = 'mime_type';").rows.size > 0
            deprecations << "Column mime_type for folio_files table is deprecated. Remove it in a custom migration."
          end

          if ActiveRecord::Base.connection.exec_query("SELECT column_name FROM information_schema.columns WHERE table_name = 'folio_private_attachments' AND column_name = 'mime_type';").rows.size > 0
            deprecations << "Column mime_type for folio_private_attachments table is deprecated. Remove it in a custom migration."
          end
        rescue ActiveRecord::NoDatabaseError
        end

        if deprecations.present?
          puts "\nFolio deprecations:"
          deprecations.each do |msg|
            Raven.capture_message(msg) if defined?(Raven)

            if defined?(logger)
              logger.error(msg)
            else
              puts "- Column mime_type for folio_files table is deprecated. Remove it in a custom migration."
            end
          end

          puts ""
        end
      end
    rescue StandardError
    end
  end
end
