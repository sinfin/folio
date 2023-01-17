# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

module Folio
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ::Folio::GeneratorBase

      desc "Creates folio initializer, routes and copies locale files to your application."

      source_root Folio::Engine.root.join("lib/templates")

      def add_gems
        gsub_file "Gemfile", "  # Display performance information such as SQL time and flame graphs for each request in your browser.\n  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md\n  gem 'rack-mini-profiler', '~> 2.0'\n", ""

        gem "premailer-rails"
        gem "rubyzip"

        gem "rack-mini-profiler"
        gem "show_for"
        gem "sprockets", "~> 4.0"
        gem "sprockets-rails" # remove if twice in Gemfile
        gem "sentry-raven"

        gem "dragonfly_libvips", github: "sinfin/dragonfly_libvips", branch: "more_geometry" # could not be in gemspec, because of GITHUB

        gem "cells-rails", "~> 0.1.5"
        gem "cells-slim", "~> 0.0.6" # version 0.1.0 drops Rails support and I was not able to make it work

        gem_group :development do
          gem "rubocop"
          gem "rubocop-minitest"
          gem "rubocop-performance"
          gem "rubocop-rails"
          gem "rubocop-rails_config"
          gem "rubocop-rake"
          gem "annotate"
          gem "guard-rubocop"
          gem "guard-slimlint"
          gem "letter_opener"
          gem "pry-rails"
          gem "slack-notifier"
          gem "better_errors"
          gem "binding_of_caller"
        end

        gem_group :development, :test do
          gem "faker"
          gem "pry-byebug"
        end

        gem_group :test do
          gem "factory_bot"
        end
      end

      def rm_rails_new_stuff
        [
          "app/views/layouts/application.html.erb",
          "public/404.html",
          "public/422.html",
          "public/500.html",
        ].each do |path|
          full_path = Rails.root.join(path)
          ::File.delete(full_path) if ::File.exist?(full_path)
        end
      end

      def copy_templates
        [
          ".env.sample",
          "app/controllers/application_controller.rb",
          "app/controllers/errors_controller.rb",
          "app/controllers/home_controller.rb",
          "app/controllers/pages_controller.rb",
          "app/lib/application_cell.rb",
          "app/lib/application_namespace_path/cache_keys.rb",
          "app/lib/application_namespace_path/current_methods.rb",
          "app/models/application_namespace_path.rb",
          "app/models/application_namespace_path/page/homepage.rb",
          "app/models/application_record.rb",
          "app/models/concerns/application_namespace_path/menu/base.rb",
          "app/overrides/cells/folio/ui_cell_override.rb",
          "app/overrides/cells/folio/ui/atoms_cell_override.rb",
          "app/overrides/controllers/folio/console/api/links_controller_override.rb",
          "app/views/layouts/folio/application.slim",
          "config/database.yml",
          "config/initializers/assets.rb",
          "config/initializers/folio.rb",
          "config/initializers/namespace.rb",
          "config/initializers/raven.rb",
          "config/initializers/smtp.rb",
          "config/locales/application_namespace_path/menu.cs.yml",
          "config/locales/application_namespace_path/menu.en.yml",
          "config/routes.rb",
          "config/sitemap.rb",
          "data/atoms_showcase.yml",
          "data/seed/pages/homepage.yml",
          "db/seeds.rb",
          "db/migrate/20220120132205_rm_files_mime_type_column.rb",
          "db/migrate/20220214083648_rm_private_attachments_mime_type_column.rb",
          "lib/tasks/developer_tools.rake",
          "public/maintenance.html",
          "test/factories.rb",
          "test/test_helper.rb",
          "vendor/assets/bower.json",
        ].each { |f| template "#{f}.tt", f.gsub("application_namespace_path", application_namespace_path) }

        template ".env.sample.tt", ".env"
      end

      def copy_files
        [
          ".gitignore",
          ".rubocop.yml",
          ".slim-lint.yml",
          "app/assets/config/manifest.js",
          "app/views/devise/invitations/edit.slim",
          "app/views/folio/pages/show.slim",
          "app/views/home/index.slim",
          "bin/bower",
          "config/secrets.yml",
          "data/email_templates_data.yml",
          "Guardfile",
          "lib/tasks/auto_annotate_models.rake",
          "vendor/assets/bower_components/.keep",
          "vendor/assets/redactor/redactor.css",
          "vendor/assets/redactor/redactor.js",
        ].each { |f| copy_file f, f }

        [
          "app/cells/#{application_namespace_path}/.keep",
        ].each do |f|
          FileUtils.mkdir_p(::File.dirname(f))
          FileUtils.touch(f)
        end

        copy_file Folio::Engine.root.join(".ruby-version"), ".ruby-version"
      end

      def mkdir_folders
        [
          ::Rails.root.join("app/cells/#{project_name}")
        ].each do |path|
          FileUtils.mkdir_p path
        end
      end

      def application_settings
        return if ::File.readlines(Rails.root.join("config/application.rb")).grep('Rails.root.join("lib")').any?

# cannot use <<~'RUBY' here, because ALL lines need to be 4 spaces intended
        inject_into_file "config/application.rb", after: /config\.load_defaults.+\n/ do <<-'RUBY'
    config.exceptions_app = self.routes

    config.time_zone = "Prague"

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
      g.test_framework :test_unit, fixture: false
    end

    I18n.available_locales = [:cs, :en]
    I18n.default_locale = :cs

    config.folio_console_locale = I18n.default_locale
    config.autoload_paths << Rails.root.join("app/lib")
    config.eager_load_paths << Rails.root.join("app/lib")

    overrides = [
      Folio::Engine.root.join("app/overrides").to_s,
      Rails.root.join("app/overrides").to_s,
    ]

    overrides.each { |override| Rails.autoloaders.main.ignore(override) }

    config.to_prepare do
      overrides.each do |override|
        Dir.glob("#{override}/**/*_override.rb").each do |file|
          load file
        end
      end
    end

        RUBY
        end
      end

      def development_settings
        gsub_file "config/environments/development.rb", "config.action_mailer.raise_delivery_errors = false" do
          [
            "  config.action_mailer.raise_delivery_errors = true",
            "  config.action_mailer.delivery_method = :letter_opener",
            "  config.action_mailer.perform_deliveries = true",
          ].join("\n")
        end
      end

      def production_settings
        gsub_file "config/environments/production.rb", "# config.assets.css_compressor = :sass" do
          [
            "config.assets.js_compressor = Folio::SelectiveUglifier.new(harmony: true)",
            "# config.assets.css_compressor = :sass",
          ].join("\n  ")
        end
      end

      def log_tag_settings
        %w[config/environments/production.rb].each do |path|
          gsub_file path,
                    "config.log_tags = [ :request_id ]",
                    <<~RUBY.chomp
                      config.log_tags = [
                          -> request { "u=\#{request.cookie_jar.signed[:u_for_log] || "nil"}" },
                          -> request { "s=\#{request.cookie_jar.signed[:s_for_log] || "nil"}" },
                          :request_id,
                        ]
                    RUBY
        end
      end

      def chmod_files
        [
          "bin/bower",
        ].each do |file|
          ::File.chmod(0775, Rails.root.join(file))
        end
      end

      private
        def project_name
          @project_name ||= Rails.root.basename.to_s
        end

        def project_classnames_prefix
          project_name[0]
        end
    end
  end
end
