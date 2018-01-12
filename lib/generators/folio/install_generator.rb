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
        gem 'pg'

        gem_group :development do
          gem 'rbnacl', version: '< 5.0'
          gem 'rbnacl-libsodium'
          gem 'bcrypt_pbkdf', version: '< 2.0'

          gem 'devise-bootstrapped'
          gem 'byebug'
          gem 'pry-rails'
          gem 'rubocop-rails'
          gem 'guard-rubocop'
          gem 'guard-coffeelint'
          gem 'faker'
          gem 'factory_girl_rails', version: '~> 4.8.0'
          gem 'annotate'
        end
      end

      def copy_templates
        [
          '.env.sample',
          'bin/sprites',
          'config/sitemap.rb',
          'config/schedule.rb',
          'config/database.yml',
          'vendor/assets/bower.json',
        ].each { |f| template "#{f}.erb", f }

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
          'app/assets/stylesheets/_cells.scss.erb',
          'app/assets/stylesheets/_custom_bootstrap.sass',
          'app/assets/stylesheets/_print.sass',
          'app/assets/stylesheets/_sprites.scss',
          'app/assets/stylesheets/_variables.sass',
          'app/assets/stylesheets/application.sass',
          'app/assets/stylesheets/modules/.keep',
          'app/assets/stylesheets/modules/_turbolinks.sass',
          'app/controllers/application_controller.rb',
          'app/controllers/pages_controller.rb',
          'bin/bower',
          'config/secrets.yml',
          'config/initializers/assets.rb',
          'config/initializers/folio.rb',
          'config/routes.rb',
          'lib/application_cell.rb',
          'vendor/assets/bower_components/.keep',
          'test/test_helper.rb',
        ].each { |f| copy_file f, f }
      end

      def application_settings
        return if File.readlines(Rails.root.join('config/application.rb')).grep("Rails.root.join('lib')").any?

        inject_into_file 'config/application.rb', after: "# -- all .rb files in that directory are automatically loaded.\n" do <<-'RUBY'
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    I18n.available_locales = [:cs, :en]
    I18n.default_locale = :cs
        RUBY
        end
      end

      def setup_routes
        route "mount Folio::Engine => '/'"
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
