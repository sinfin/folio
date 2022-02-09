# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::DeviseGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  desc "Sets devise up for application"
  source_root File.expand_path("templates", __dir__)

  def copy_templates
    puts "Adding controllers"

    path = File.expand_path("templates", __dir__)

    Dir.glob("#{path}/**/*.tt").each do |file_path|
      template_path = file_path.gsub("#{path}/", "")
      target_path = template_path.gsub(/\.tt\Z/, "")
                                 .gsub("application_namespace_path",
                                       application_namespace_path)

      template template_path, target_path
    end
  end

  def add_routes
    if File.read("config/routes.rb").include?('devise_for :users, class_name: "Folio::User",')
      puts "Skipping route - users already added"
      return
    else
      puts "Adding route"
    end

    str = <<~'RUBY'
      devise_for :accounts, class_name: "Folio::Account",
                            module: "folio/accounts"

      devise_for :users, class_name: "Folio::User",
                         module: "application_namespace_path/folio/users",
                         omniauth_providers: Rails.application.config.folio_users_omniauth_providers

    RUBY

    str = str.gsub("application_namespace_path", application_namespace_path)

    inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
      str
    end
  end

  def add_assets
    application_js = Rails.root.join("app/assets/javascripts/application.js")

    if File.exist?(application_js)
      if File.read(application_js).include?("require folio/devise")
        puts "Skipping JS - folio/devise present"
      else
        puts "Adding JS"
        append_to_file "app/assets/javascripts/application.js" do
          "//= require folio/devise"
        end
      end
    else
      puts "Skipping JS - no application.js"
    end

    application_sass = Rails.root.join("app/assets/stylesheets/application.sass")

    if File.exist?(application_sass)
      if File.read(application_sass).include?("@import 'folio/devise'")
        puts "Skipping css - folio/devise present"
      else
        puts "Adding css"
        append_to_file "app/assets/stylesheets/application.sass" do
          "@import 'folio/devise'"
        end
      end
    else
      puts "Skipping css - no application.sass"
    end
  end
end
