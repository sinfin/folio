# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::PreparedAtomGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  desc "Creates usefull atoms for use in CMS pages (text, image, person, document ...). You can get just one of them (`rails g folio:prepared_atom card/small`) or all of them (`rails g folio:prepared_atom all`)"

  source_root File.expand_path("templates", __dir__)

  class UnknownAtomKey < StandardError; end

  def create
    allowed_keys = Dir.entries(Folio::Engine.root.join("lib/generators/folio/prepared_atom/templates")).reject { |name| name.include?(".") }

    if name == "all"
      keys = allowed_keys
    elsif allowed_keys.include?(name)
      keys = [name.to_sym]
    else
      raise UnknownAtomKey, "Unknown atom key #{name}. Allowed keys: #{allowed_keys.join(', ')}"
    end

    base = ::Folio::Engine.root.join("lib/generators/folio/prepared_atom/templates/").to_s

    keys.each do |key|
      @atom_name = key

      Dir["#{base}#{key}/#{key}.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/models/#{application_namespace_path}/atom/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      is_molecule = File.read("#{base}#{key}/#{key}.rb.tt").match?("self.molecule")
      component_directory = is_molecule ? "molecule" : "atom"

      Dir["#{base}#{key}/component/#{key}_component.*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/components/#{application_namespace_path}/#{component_directory}/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/component/")}"
      end

      Dir["#{base}#{key}/component/#{key}_component_test.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "test/components/#{application_namespace_path}/#{component_directory}/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/component/")}"
      end

      i18n_path = "#{base}#{key}/i18n.yml"
      if File.exist?(i18n_path)
        raw_yaml = File.read(i18n_path).gsub("application_namespace_path", application_namespace_path)
        add_atom_to_i18n_ymls(YAML.load(raw_yaml))
      end
    end
  end

  def update_controller
    template "atoms_controller.rb.tt", "app/controllers/#{application_namespace_path}/atoms_controller.rb"

    routes_s = File.read(folio_generators_root.join("config/routes.rb"))

    str = "    resource :atoms, only: %i[show]"

    if routes_s.exclude?(str)
      inject_into_file "config/routes.rb", before: /scope module: :#{application_namespace_path}, as: :#{application_namespace_path} do/ do
        str
      end
    end

    views_base = ::Folio::Engine.root.join("lib/generators/folio/prepared_atom/templates/").to_s

    Dir["#{views_base}*.slim.tt"].each do |path|
      relative_path = path.to_s.delete_prefix(views_base)

      template relative_path, "app/views/#{application_namespace_path}/atoms/#{File.basename(path).delete_suffix('.tt')}"
    end
  end

  private
    def name
      super.downcase
    end
end
