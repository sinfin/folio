# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::PreparedAtomGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  PREPARED_ATOMS = %i[
    text
    title
    images
  ]

  class UnknownAtomKey < StandardError; end

  def create
    if name == "all"
      keys = PREPARED_ATOMS
    elsif PREPARED_ATOMS.include?(name.to_sym)
      keys = [name.to_sym]
    else
      raise UnknownAtomKey, "Unknown atom key #{name}. Allowed keys: #{PREPARED_ATOMS.join(', ')}"
    end

    base = ::Folio::Engine.root.join("lib/generators/folio/prepared_atom/templates/").to_s

    keys.each do |key|
      @atom_name = key

      Dir["#{base}#{key}/#{key}.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/models/#{global_namespace_path}/atom/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/")}"
      end

      Dir["#{base}#{key}/cell/#{key}_cell.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/cells/#{global_namespace_path}/atom/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/cell/")}"
      end

      Dir["#{base}#{key}/cell/#{key}_cell_test.rb.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "test/cells/#{global_namespace_path}/atom/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/cell/")}"
      end

      Dir["#{base}#{key}/cell/#{key}/**/*.tt"].each do |path|
        relative_path = path.to_s.delete_prefix(base)
        template relative_path, "app/cells/#{global_namespace_path}/atom/#{relative_path.delete_suffix('.tt').delete_prefix("#{key}/cell/")}"
      end

      i18n_path = "#{base}#{key}/i18n.yml"
      if File.exist?(i18n_path)
        add_atom_to_i18n_ymls(YAML.load_file(i18n_path))
      end
    end
  end

  private
    def name
      super.downcase
    end
end
