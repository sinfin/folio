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
          gem 'guard-slimlint'
          gem 'faker'
          gem 'factory_girl_rails', version: '~> 4.8.0'
          gem 'annotate'
          gem 'slack-notifier'

          gem 'capistrano-rails', require: false
          gem 'capistrano-sinfin', git: 'git@bitbucket.org:Sinfin/capistrano-sinfin.git', branch: 'master'
          gem 'capistrano-serviceman', github: 'Sinfin/capistrano-serviceman', branch: 'master'
        end
      end

      def rm_original_assets
        [
          'app/assets/stylesheets/application.css',
          'app/views/layouts/application.html.erb',
        ].each do |path|
          full_path = Rails.root.join(path)
          File.delete(full_path) if File.exists?(full_path)
        end
      end

      def copy_templates
        [
          '.env.sample',
          'app/views/layouts/application.slim',
          'bin/sprites',
          'config/sitemap.rb',
          'config/schedule.rb',
          'config/database.yml',
          'db/seeds.rb',
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
          'app/controllers/home_controller.rb',
          'app/views/home/index.slim',
          'app/views/pages/show.slim',
          'bin/bower',
          'config/secrets.yml',
          'config/initializers/assets.rb',
          'config/initializers/folio.rb',
          'config/initializers/raven.rb',
          'config/initializers/smtp.rb',
          'config/routes.rb',
          'lib/application_cell.rb',
          'vendor/assets/bower_components/.keep',
          'vendor/assets/redactor/redactor.css',
          'vendor/assets/redactor/redactor.js',
          'test/factories.rb',
          'test/test_helper.rb',
        ].each { |f| copy_file f, f }

        copy_file Folio::Engine.root.join('.ruby-version'), '.ruby-version'
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

      def gemfile_rails_assets
        return if File.readlines(Rails.root.join('config/application.rb')).grep('rails-assets.org').any?

        inject_into_file 'Gemfile', after: "source 'https://rubygems.org'" do <<-'RUBY'

source 'https://rails-assets.org'
        RUBY
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
