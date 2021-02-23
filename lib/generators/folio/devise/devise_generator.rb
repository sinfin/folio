# frozen_string_literal: true

class Folio::DeviseGenerator < Rails::Generators::Base
  desc "Sets devise up for application"
  source_root File.expand_path("templates", __dir__)

  def copy_templates
    puts "Adding controllers"

    path = File.expand_path("templates", __dir__)

    Dir.glob("#{path}/**/*.tt").each do |file_path|
      template_path = file_path.gsub("#{path}/", "")
      target_path = template_path.gsub(/\.tt\Z/, "")
                                 .gsub("application_dir_namespace",
                                       application_dir_namespace)

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
                         module: "application_dir_namespace/folio/users",
                         omniauth_providers: Rails.application.config.folio_users_omniauth_providers

    RUBY

    str = str.gsub("application_dir_namespace", application_dir_namespace)

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

  private
    def application_module
      @application_module ||= Rails.application.class.parent
    end

    def application_dir_namespace
      @application_dir_namespace ||= application_module.to_s.underscore
    end
end
