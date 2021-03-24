# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::UiGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  CELLS = {
    disclaimer: {},
    flash: {},
    footer: {},
    header: {},
    ico: {},
    icon: {},
    menu: {},
    navigation: {},
    pagy: {},
    tabs: {},
  }

  class UnknownCell < StandardError; end

  def create
    if name == "all"
      keys = CELLS.keys
    elsif CELLS.keys.include?(name.to_sym)
      keys = [name.to_sym]
    else
      raise UnknownCell, "Unknown cell #{name}. Allowed keys: #{CELLS.keys.join(', ')}"
    end

    base = ::Folio::Engine.root.join("lib/generators/folio/ui/templates/").to_s

    keys.each do |key|
      Dir["#{base}#{key}/#{key}_cell.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/cells/#{global_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/#{key}_cell_test.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "test/cells/#{global_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/#{key}/**/*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/cells/#{global_namespace_path}/ui/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end
    end
  end

  def update_i18n_ymls(values = {})
    I18n.available_locales.each do |locale|
      app_path = Rails.root.join("config/locales/ui.#{locale}.yml")
      template_path = Folio::Engine.root.join("lib/generators/folio/ui/templates/ui.#{locale}.yml")

      unless File.exist?(template_path)
        puts "Missing #{template_path.to_s.delete_prefix(Folio::Engine.root.to_s)}"
      else
        new_hash = {
          locale.to_s => {
            global_namespace_path => {
              "ui" => YAML.load_file(template_path),
            }
          }
        }

        if File.exist?(app_path)
          hash = new_hash.deep_merge(YAML.load_file(app_path))
          puts "Updating #{app_path.to_s.delete_prefix(Folio::Engine.root.to_s)}"
        else
          hash = new_hash
          puts "Creating #{app_path.to_s.delete_prefix(Folio::Engine.root.to_s)}"
        end

        File.write app_path, hash.to_yaml(line_width: -1)
      end
    end
  end

  private
    def name
      super.downcase
    end
end
