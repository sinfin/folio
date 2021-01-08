# frozen_string_literal: true

class Folio::BlogGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def copy_templates
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
    return if File.read("config/routes.rb").include?("namespace :blog")
    inject_into_file "config/routes.rb", after: "scope module: :#{application_dir_namespace}, as: :#{application_dir_namespace} do\n" do <<~'RUBY'
      namespace :blog do
        resources :articles, only: %i[index show] do
          member { get :preview }
        end
        resources :categories, only: %i[show] do
          member { get :preview }
        end
      end

    RUBY
    end

    inject_into_file "config/routes.rb", after: "scope module: :folio do\n    namespace :console do\n      namespace :#{application_dir_namespace} do\n" do <<~'RUBY'
        namespace :blog do
          resources :articles, except: %i[show]
          resources :categories, except: %i[show]
        end

    RUBY
    end
  end

  def add_factories
    return if File.read("test/factories.rb").include?("#{application_dir_namespace}_blog_article")

    content = <<~'RUBY'
      factory :application_dir_namespace_blog_article, class: "application_module::Blog::Article" do
        sequence(:title) { |i| "Article title #{i + 1}" }
        perex { "perex" }
      end

      factory :application_dir_namespace_blog_category, class: "application_module::Blog::Category" do
        sequence(:title) { |i| "Category title #{i + 1}" }
      end

    RUBY

    content = content.gsub("application_dir_namespace", application_dir_namespace)
                     .gsub("application_module", application_module.to_s)

    inject_into_file "test/factories.rb", after: "FactoryBot.define do\n" do
      content
    end
  end

  private
    def application_module
      @application_module ||= Rails.application.class.parent
    end

    def app_module_spacing
      @app_module_spacing ||= application_module.to_s.gsub(/\w/, " ")
    end

    def application_dir_namespace
      @application_dir_namespace ||= application_module.to_s.underscore
    end

    def blog_namespace
      @blog_namespace ||= "#{application_module}::Blog"
    end
end
