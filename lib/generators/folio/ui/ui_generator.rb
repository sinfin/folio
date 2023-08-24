# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::UiGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  desc "Creates usefull cells for basic things in UI (headers, cards, footers...)."

  source_root File.expand_path("templates", __dir__)

  class UnknownCell < StandardError; end

  def create
    allowed_keys = Dir.entries(Folio::Engine.root.join("lib/generators/folio/ui/templates")).reject { |name| name.starts_with?(".") }

    if name == "all"
      keys = allowed_keys
    elsif allowed_keys.include?(name)
      keys = [name.to_sym]
    else
      raise UnknownCell, "Unknown cell #{name}. Allowed keys: #{allowed_keys.keys.join(', ')}"
    end

    base = ::Folio::Engine.root.join("lib/generators/folio/ui/templates/").to_s

    keys.each do |key|
      Dir["#{base}#{key}/#{key}_cell.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/cells/#{application_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/#{key}_cell_test.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "test/cells/#{application_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/#{key}/**/*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/cells/#{application_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/models/**/*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, relative_path.delete_prefix("#{key}/models/").gsub("application_namespace_path", application_namespace_path).delete_suffix(".tt")
      end

      Dir["#{base}#{key}/#{key}_component.*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/components/#{application_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/#{key}_component_test.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "test/components/#{application_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end
    end
  end

  def update_controller
    template "ui_controller.rb.tt", "app/controllers/#{application_namespace_path}/ui_controller.rb"

    routes_s = File.read(Rails.root.join("config/routes.rb"))

    if routes_s.exclude?("resource :ui")
      str = <<-RUBY

    resource :ui, only: %i[show], controller: "ui" do
      get :alerts
      get :buttons
      get :forms
      get :typo
      get :icons
    end
      RUBY

      inject_into_file "config/routes.rb", after: /scope module: :#{application_namespace_path}, as: :#{application_namespace_path} do/ do
        str
      end
    end
  end

  def update_i18n_ymls
    I18n.available_locales.each do |locale|
      app_path = Rails.root.join("config/locales/ui.#{locale}.yml")
      template_path = Folio::Engine.root.join("lib/generators/folio/ui/templates/ui.#{locale}.yml")

      unless File.exist?(template_path)
        puts "Missing #{template_path.to_s.delete_prefix(Folio::Engine.root.to_s)}"
      else
        new_hash = {
          locale.to_s => {
            application_namespace_path => {
              "ui" => YAML.load_file(template_path),
            }
          }
        }

        if File.exist?(app_path)
          hash = new_hash.deep_merge(YAML.load_file(app_path))
        else
          hash = new_hash
        end

        File.write app_path, hash.to_yaml(line_width: -1)
      end
    end
  end

  def copy_seed_ymls
    base = ::Folio::Engine.root.join("lib/generators/folio/ui/templates/ymls/").to_s

    Dir["#{base}**/*.yml.tt"].each do |path|
      relative_path = path.to_s.delete_prefix(base)
      template "ymls/#{relative_path}", relative_path.delete_suffix(".tt")
    end
  end

  private
    def name
      super.downcase
    end
end
