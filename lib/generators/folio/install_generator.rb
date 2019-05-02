# frozen_string_literal: true

module Folio
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Creates folio initializer, routes and copies locale files to your application.'

      source_root Folio::Engine.root.join('lib/templates')

      def add_gems
        gem 'dotenv-rails'
        gem 'autoprefixer-rails'
        gem 'slim-rails'
        gem 'cells'
        gem 'cells-rails'
        gem 'cells-slim'
        gem 'route_translator'
        gem 'breadcrumbs_on_rails'
        gem 'sentry-raven'
        gem 'pg', version: '~> 0.21.0'
        gem 'devise-i18n'
        gem 'rails-i18n'
        gem 'actionpack-page_caching'
        gem 'mini_racer'

        gem_group :test do
          gem 'factory_bot'
          gem 'rack_session_access'
        end

        gem_group :development, :test do
          gem 'faker', require: false
        end

        gem_group :development do
          gem 'rbnacl', version: '< 5.0'
          gem 'rbnacl-libsodium'
          gem 'bcrypt_pbkdf', version: '< 2.0'
          gem 'ed25519'

          gem 'pry-rails'
          gem 'rubocop-rails_config'
          gem 'guard-rubocop'
          gem 'guard-coffeelint'
          gem 'guard-slimlint'
          gem 'annotate'
          gem 'slack-notifier'
          gem 'letter_opener'

          gem 'capistrano-rails', require: false
          gem 'capistrano-sinfin', git: 'git@bitbucket.org:Sinfin/capistrano-sinfin.git', branch: 'master'
          gem 'capistrano-serviceman', github: 'Sinfin/capistrano-serviceman', branch: 'master'
          gem 'rack-mini-profiler', require: false

          gem 'better_errors'
          gem 'binding_of_caller'
        end
      end

      def rm_rails_new_stuff
        [
          'app/assets/stylesheets/application.css',
          'app/views/layouts/application.html.erb',
          'public/404.html',
          'public/422.html',
          'public/500.html',
        ].each do |path|
          full_path = Rails.root.join(path)
          File.delete(full_path) if File.exist?(full_path)
        end
      end

      def copy_templates
        [
          '.env.sample',
          'app/views/layouts/folio/application.slim',
          'bin/sprites',
          'config/sitemap.rb',
          'config/schedule.rb',
          'config/database.yml',
          'config/locales/activerecord.cs.yml',
          'config/locales/activerecord.en.yml',
          'db/seeds.rb',
          'vendor/assets/bower.json',
        ].each { |f| template "#{f}.erb", f }

        [
          'test/factories.rb',
          'test/test_helper.rb',
          'app/controllers/application_controller.rb',
          'app/controllers/pages_controller.rb',
          'app/controllers/errors_controller.rb',
          'app/controllers/home_controller.rb',
          'app/models/application_record.rb',
          'config/initializers/assets.rb',
          'config/initializers/raven.rb',
          'config/initializers/smtp.rb',
          'config/routes.rb',
          'lib/application_cell.rb',
        ].each { |f| template "#{f}.tt", f }

        template '.env.sample.erb', '.env'
      end

      def copy_files
        [
          '.gitignore',
          '.rubocop.yml',
          '.slim-lint.yml',
          'Guardfile',
          'app/assets/images/sprites@1x/.keep',
          'app/assets/images/sprites@2x/.keep',
          'app/assets/javascripts/application.js',
          'app/assets/javascripts/non_turbo.js',
          'app/assets/stylesheets/_cells.scss.erb',
          'app/assets/stylesheets/_custom_bootstrap.sass',
          'app/assets/stylesheets/_fonts.scss',
          'app/assets/stylesheets/_print.sass',
          'app/assets/stylesheets/_sprites.scss',
          'app/assets/stylesheets/_variables.sass',
          'app/assets/stylesheets/application.sass',
          'app/assets/stylesheets/folio/console/_main_app.sass',
          'app/assets/stylesheets/modules/.keep',
          'app/assets/stylesheets/modules/_turbolinks.sass',
          'app/assets/stylesheets/modules/_bootstrap-overrides.sass',
          'app/assets/stylesheets/modules/bootstrap-overrides/_type.sass',
          'app/assets/stylesheets/modules/bootstrap-overrides/mixins/_type.sass',
          'app/views/devise/mailer/invitation_instructions.html.erb',
          'app/views/devise/mailer/invitation_instructions.text.erb',
          'app/views/home/index.slim',
          'app/views/folio/pages/show.slim',
          'app/views/folio/console/partials/_appended_menu_items.slim',
          'app/views/folio/console/partials/_prepended_menu_items.slim',
          'bin/bower',
          'config/secrets.yml',
          'lib/tasks/auto_annotate_models.rake',
          'vendor/assets/bower_components/.keep',
          'vendor/assets/redactor/redactor.css',
          'vendor/assets/redactor/redactor.js',
        ].each { |f| copy_file f, f }

        copy_file Folio::Engine.root.join('.ruby-version'), '.ruby-version'
      end

      def application_settings
        return if File.readlines(Rails.root.join('config/application.rb')).grep("Rails.root.join('lib')").any?

        inject_into_file 'config/application.rb', after: /config\.load_defaults.+\n/ do <<-'RUBY'
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    config.exceptions_app = self.routes

    config.time_zone = 'Prague'

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
      g.test_framework :test_unit, fixture: false
    end

    I18n.available_locales = [:cs, :en]
    I18n.default_locale = :cs

    config.folio_console_locale = I18n.default_locale
        RUBY
        end
      end

      def development_settings
        gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send.*\n/, ''

        gsub_file 'config/environments/development.rb', /  config\.action_mailer\.raise_delivery_errors = false/ do
          [
            'config.action_mailer.raise_delivery_errors = true',
            'config.action_mailer.delivery_method = :letter_opener',
            'config.action_mailer.perform_deliveries = true',
          ].join("\n  ")
        end
      end

      def test_settings
        inject_into_file 'config/environments/test.rb', before: '# Raises error for missing translations' do
          "config.middleware.use RackSessionAccess::Middleware\n\n  "
        end
      end

      def production_settings
        inject_into_file 'config/environments/production.rb', after: /config\.action_controller\.perform_caching\s*=\s*true/ do
          "\n  config.action_controller.page_cache_directory = Rails.root.join('public', 'cached_pages')"
        end
      end

      def setup_routes
        route "mount Folio::Engine => '/'"
      end

      def chmod_files
        [
          'bin/bower',
          'bin/sprites'
        ].each do |file|
          File.chmod(0775, Rails.root.join(file))
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
