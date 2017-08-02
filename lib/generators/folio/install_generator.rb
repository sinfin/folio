module Folio
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../templates', __FILE__)

      desc 'Creates folio initializer, routes and copy locale files to your application.'
      # class_option :orm

      def copy_initializer
        template '../templates/.env.sample.erb', '.env.sample'
        template '../templates/config/sitemap.rb.erb', 'config/sitemap.rb'
        template '../templates/config/schedule.rb.erb', 'config/schedule.rb'
      end

      #       def install_assets
      #         require 'rails'
      #         require 'active_admin'
      #
      #         template '../templates/active_admin.js',
      # 'app/assets/javascripts/active_admin.js'
      #         template '../templates/active_admin.css.scss',
      # 'app/assets/stylesheets/active_admin.css.scss'
      #       end

      def setup_routes
        route "mount Folio::Engine => '/'"
      end

      def self.source_root
        File.expand_path('../../../templates', __FILE__)
      end

      def show_readme
        readme 'README'
      end
    end
  end
end
