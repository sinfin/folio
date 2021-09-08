# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::SearchGenerator < Rails::Generators::Base
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def copy_templates
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
    return if File.read(Rails.root.join("config/routes.rb")).include?("resource :search")

    inject_into_file "config/routes.rb", after: "scope module: :#{application_namespace_path}, as: :#{application_namespace_path} do\n" do <<~'RUBY'
      resource :search, only: %i[show] do
        get :autocomplete
        get :pages
      end

    RUBY
    end
  end
end
