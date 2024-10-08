# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::UiGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  desc "Creates usefull cells for basic things in UI (headers, cards, footers...)."

  source_root File.expand_path("templates", __dir__)

  class UnknownCell < StandardError; end

  def create
    allowed_keys = Dir.entries(Folio::Engine.root.join("lib/generators/folio/ui/templates")).reject do |name|
      name.starts_with?(".") || name == "views" || name == "input"
    end

    %w[console_preview input menu_toolbar].each do |key|
      allowed_keys += Dir.entries(Folio::Engine.root.join("lib/generators/folio/ui/templates/#{key}")).filter_map do |name|
        unless name.starts_with?(".")
          "#{key}/#{name}"
        end
      end
    end

    if name == "all"
      keys = allowed_keys
    elsif allowed_keys.include?(name)
      keys = [name.to_sym]
    else
      raise UnknownCell, "Unknown cell #{name}. Allowed keys: #{allowed_keys.keys.join(', ')}"
    end

    base = ::Folio::Engine.root.join("lib/generators/folio/ui/templates/").to_s

    keys.each do |key_sym|
      key = key_sym.to_s

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

      Dir["#{base}#{key}/#{File.basename(key)}_component.*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)

        target = if key.include?("/")
          subpath = key.split("/", 2).last
          relative_path.delete_suffix(".tt").gsub("#{subpath}/#{subpath}", subpath)
        else
          relative_path.delete_suffix(".tt").delete_prefix("#{File.basename(key)}/")
        end

        template relative_path, "app/components/#{application_namespace_path}/ui/#{target}"
      end

      Dir["#{base}#{key}/#{File.basename(key)}_component_test.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        target = if key.include?("/")
          subpath = key.split("/", 2).last
          relative_path.delete_suffix(".tt").gsub("#{subpath}/#{subpath}", subpath)
        else
          relative_path.delete_suffix(".tt").delete_prefix("#{File.basename(key)}/")
        end

        template relative_path, "test/components/#{application_namespace_path}/ui/#{target}"
      end
    end
  end

  def update_controller
    template "ui_controller.rb.tt", "app/controllers/#{application_namespace_path}/ui_controller.rb"

    routes_s = File.read(folio_generators_root.join("config/routes.rb"))

    if routes_s.exclude?("draw \"#{application_namespace_path}/ui\"i")
      str = "draw \"#{application_namespace_path}/ui\"\n\n"

      inject_into_file "config/routes.rb", before: /scope module: :#{application_namespace_path}, as: :#{application_namespace_path} do/ do
        str
      end
    end

    views_base = ::Folio::Engine.root.join("lib/generators/folio/ui/templates/").to_s

    Dir["#{views_base}views/*.slim.tt"].each do |path|
      relative_path = path.to_s.delete_prefix(views_base)

      template relative_path, "app/views/#{application_namespace_path}/ui/#{File.basename(path).delete_suffix('.tt')}"
    end
  end

  def update_helper
    template "ui_helper.rb.tt", "app/helpers/#{application_namespace_path}/ui_helper.rb"
  end

  def update_i18n_ymls
    I18n.available_locales.each do |locale|
      app_path = folio_generators_root.join("config/locales/ui.#{locale}.yml")
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

  def copy_routes
    template "ui-routes.rb", "config/routes/#{application_namespace_path}/ui.rb"
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
