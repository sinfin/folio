# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end

    # fix deprecation warning - Using legacy connection handling is deprecated
    config.active_record.legacy_connection_handling = false

    # can remove this once we get rid of "serialize" in app/models/concerns/folio/thumbnails.rb and app/models/folio/newsletter_subscription.rb
    config.active_record.yaml_column_permitted_classes = [Symbol, ActiveSupport::TimeWithZone, Time, ActiveSupport::TimeZone]

    config.folio_crossdomain_devise = false
    config.folio_dragonfly_keep_png = true
    config.folio_public_page_title_reversed = false
    config.folio_using_traco = false
    config.folio_pages_audited = false
    config.folio_pages_ancestry = false
    config.folio_pages_perex_richtext = false
    config.folio_pages_locales = false
    config.folio_console_locale = :cs
    config.folio_console_report_redirect = :console_pages_path
    config.folio_console_sidebar_link_class_names = nil
    config.folio_console_sidebar_prepended_link_class_names = []
    config.folio_console_sidebar_appended_link_class_names = []
    config.folio_console_sidebar_runner_up_link_class_names = []
    config.folio_console_sidebar_skip_link_class_names = []
    config.folio_console_sidebar_force_hide_users = false
    config.folio_console_sidebar_title_items = -> (sidebar_cell) { nil }
    config.folio_console_sidebar_title_new_item = -> (sidebar_cell) { nil }
    config.folio_console_sidebar_title_image_path = nil
    config.folio_console_default_routes_contstraints = {}
    config.folio_newsletter_subscription_service = :mailchimp
    config.folio_server_names = []
    config.folio_image_spacer_background_fallback = nil
    config.folio_show_transportable_frontend = false
    config.folio_modal_cell_name = nil
    config.folio_use_og_image = true
    config.folio_mailer_global_bcc = nil
    config.folio_aasm_mailer_config = {}
    config.folio_site_is_a_singleton = true
    config.folio_site_cache_current_site = true
    config.folio_site_validate_belongs_to_namespace = false
    config.folio_site_default_test_factory = nil
    config.folio_cell_generator_class_name_prefixes = {}
    config.folio_file_types_for_routes = %w[
      Folio::File::Image
      Folio::File::Document
      Folio::File::Audio
      Folio::File::Video
    ]
    config.folio_allow_users_to_console = false
    config.folio_atom_files_url = -> (file_klass) {
      url_for_args = [:console, :api, file_klass, only_path: true]

      begin
        Folio::Engine.app.url_helpers.url_for(url_for_args)
      rescue StandardError
        Rails.application.routes.url_helpers.url_for(url_for_args)
      end
    }

    config.folio_direct_s3_upload_class_names = %w[
      Folio::File
      Folio::PrivateAttachment
      Folio::SessionAttachment::Base
    ]

    config.folio_direct_s3_upload_allow_for_users = false
    config.folio_direct_s3_upload_allow_public = false
    config.folio_direct_s3_upload_attributes_for_job_proc = -> (controller) {
      {}
    }

    config.folio_users = false
    config.folio_users_require_phone = false
    config.folio_users_sign_out_everywhere = true
    config.folio_users_confirmable = false
    config.folio_users_confirm_email_change = true
    config.folio_users_publicly_invitable = true
    config.folio_users_use_address = true
    config.folio_users_omniauth_providers = %i[facebook google_oauth2 twitter2 apple]
    config.folio_users_after_ajax_sign_up_redirect = false
    config.folio_users_after_sign_in_path = :root_path
    config.folio_users_after_sign_up_path = :root_path
    config.folio_users_after_update_path_for = :root_path
    config.folio_users_after_sign_out_path = :new_user_session_path
    config.folio_users_after_accept_path = :root_path
    config.folio_users_signed_in_root_path = :root_path
    config.folio_users_after_password_change_path = :root_path
    config.folio_users_after_impersonate_path = config.folio_users_after_sign_in_path
    config.folio_users_after_impersonate_path_proc = -> (controller, user) {
      controller.main_app.send(Rails.application.config.folio_users_after_impersonate_path)
    }

    config.folio_users_non_get_referrer_rewrite_proc = -> (referrer) { }

    config.folio_console_ability_lambda = -> (ability, account) { }

    config.folio_console_react_modal_types = config.folio_file_types_for_routes

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

    initializer :append_folio_assets_paths do |app|
      app.config.assets.paths << self.root.join("app/cells")
      app.config.assets.paths << self.root.join("node_modules")
      app.config.assets.paths << self.root.join("vendor/assets/javascripts")
      app.config.assets.paths << self.root.join("vendor/assets/bower_components")
      app.config.assets.precompile += %w[
        folio/console/base.css
        folio/console/base.js
        folio/console/react/main.js
        folio/console/react/main.css
      ]
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.include?(root.to_s + "/")
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer :add_folio_maintenance_middleware do |app|
      if ENV["FOLIO_MAINTENANCE"]
        require "rack/folio/maintenance_middleware"
        app.config.middleware.use(Rack::Folio::MaintenanceMiddleware)
      end
    end

    begin
      initializer :deprecations_and_important_messages do |app|
        deprecations = []

        begin
          if ActiveRecord::Base.connection.exec_query("SELECT column_name FROM information_schema.columns WHERE table_name = 'folio_files' AND column_name = 'mime_type';").rows.size > 0
            deprecations << "Column mime_type for folio_files table is deprecated. Remove it in a custom migration."
          end

          if ActiveRecord::Base.connection.exec_query("SELECT column_name FROM information_schema.columns WHERE table_name = 'folio_private_attachments' AND column_name = 'mime_type';").rows.size > 0
            deprecations << "Column mime_type for folio_private_attachments table is deprecated. Remove it in a custom migration."
          end

          if ActiveRecord::Base.connection.exec_query("SELECT * FROM pg_indexes WHERE tablename = 'folio_pages' AND indexname = 'index_folio_pages_on_by_query';").rows.size == 0
            deprecations << "Missing index_folio_pages_on_by_query index on folio_pages. That is probably caused by using traco title_* attributes. Add a custom one."
          end

          if !Rails.env.test? && ActiveRecord::Base.connection.exec_query("SELECT id FROM folio_email_templates WHERE mailer ='Devise::Mailer' LIMIT 1;").rows.size == 0
            deprecations << "There are no email templates present. Seed them via rake folio:email_templates:idp_seed"
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
        end

        if %w[js coffee].any? { |ext| File.exist?(Rails.root.join("app/cells/folio/console/atoms/previews/main_app.#{ext}")) }
          deprecations << "The main_app js/coffee file has moved from app/cells/folio/console/atoms/previews to app/assets/javascripts/folio/console/atoms/previews"
        end

        if deprecations.present?
          puts "\nFolio deprecations:"

          deprecations.each do |msg|
            Folio::Deprecation.log(msg)
          end

          puts ""
        end
      end
    rescue StandardError
    end
  end
end
