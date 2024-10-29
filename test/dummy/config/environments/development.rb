# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = ENV.fetch("CI", false)

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # ActionMailer Config
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.perform_caching = false

  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp

    config.action_mailer.smtp_settings = {
      address:         ENV["SMTP_ADDRESS"],
      port:            ENV["SMTP_PORT"],
      domain:          ENV["SMTP_DOMAIN"],
      user_name:       ENV["SMTP_USERNAME"],
      password:        ENV["SMTP_PASSWORD"],
      authentication:  ENV["SMTP_AUTHENTICATION"] }
  else
    config.action_mailer.delivery_method = :letter_opener
  end

  # Skip MiniProfiler for mailer
  # Some clients show its output in the body of the email
  # It breaks the email preview, which makes debugging harder
  if defined?(Rack::MiniProfiler)
    Rack::MiniProfiler.config.skip_paths ||= []
    Rack::MiniProfiler.config.skip_paths << "/rails/mailers/dummy/developer_mailer/debug"
  end

  config.action_mailer.default_url_options = { host: "localhost",
                                               port: ENV["PORT"].presence || 3000,
                                               protocol: "http",
                                               locale: :cs }

  if ENV["DEV_QUEUE_ADAPTER"].present?
    config.active_job.queue_adapter = ENV["DEV_QUEUE_ADAPTER"]
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  config.hosts += [/[^.]+\.dev\.dummy\.cz/, "dev.dummy.cz", "api.dummy.cz", "lvh.me"]
end
