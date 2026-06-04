# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::BlogGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def copy_templates
    path = File.expand_path("templates", __dir__)

    Dir.glob("#{path}/**/*.tt").each do |file_path|
      template_path = file_path.gsub("#{path}/", "")
      target_path = template_path.gsub(/\.tt\Z/, "")
                                 .gsub("application_namespace_path",
                                       application_namespace_path)

      template template_path, "#{pack_path_prefix}#{target_path}"
    end
  end

  def add_routes
    return if File.read(folio_generators_root.join("config/routes.rb")).include?("namespace :blog")
    inject_into_file "config/routes.rb", after: "scope module: :#{application_namespace_path}, as: :#{application_namespace_path} do\n" do <<-'RUBY'
    namespace :blog do
      resources :articles, only: %i[show]

      get "/", to: "articles#index", as: :articles

      resources :topics, only: %i[show]

      resources :authors, only: %i[show]
    end

    RUBY
    end

    inject_into_file "config/routes.rb", after: "scope module: :folio do\n    namespace :console do\n      namespace :#{application_namespace_path} do\n" do <<-'RUBY'
        namespace :blog do
          resources :articles, except: %i[show]
          resources :authors, except: %i[show] do
            post :set_positions, on: :collection
          end
          resources :topics, except: %i[show] do
            post :set_positions, on: :collection
          end
        end

    RUBY
    end
  end

  def add_factories
    return if application_namespace == "Dummy"
    return if File.read(folio_generators_root.join("test/factories.rb")).include?("#{application_namespace_path}_blog_article")

    content = <<-'RUBY'
  factory :application_namespace_path_blog_article, class: "application_namespace::Blog::Article" do
    sequence(:title) { |i| "Article title #{i + 1}" }
    perex { "perex" }
    published { true }
    site { Folio::Site.first || create(Rails.application.config.folio_site_default_test_factory) }
  end

  factory :application_namespace_path_blog_topic, class: "application_namespace::Blog::Topic" do
    sequence(:title) { |i| "Topic title #{i + 1}" }
    published { true }
    site { Folio::Site.first || create(Rails.application.config.folio_site_default_test_factory) }
  end

  factory :application_namespace_path_blog_author, class: "application_namespace::Blog::Author" do
    first_name { "Firstname" }
    sequence(:last_name) { |i| "Lastname #{i + 1}" }
    published { true }
    site { Folio::Site.first || create(Rails.application.config.folio_site_default_test_factory) }
  end

    RUBY

    content = content.gsub("application_namespace_path", application_namespace_path)
                     .gsub("application_namespace", application_namespace.to_s)

    inject_into_file "test/factories.rb", after: "FactoryBot.define do\n" do
      content
    end
  end
end
