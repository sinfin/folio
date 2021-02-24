# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::PreparedAtomGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  PREPARED_ATOMS = {
    text: {
      cs: "Text (odstavce, tabulky, apod.)",
      en: "Text (paragraphs, tables, etc.)"
    },
    title: {
      cs: "Nadpis",
      en: "Title"
    }
  }

  class UnknownAtomKey < StandardError; end

  def create
    if name.blank? || PREPARED_ATOMS.keys.exclude?(name.to_sym)
      raise UnknownAtomKey, "Unknown atom key #{name}. Allowed keys: #{PREPARED_ATOMS.keys.join(', ')}"
    end

    template "#{name}/atom_model.rb.tt", "app/models/#{global_namespace_path}/atom/#{name}.rb"
    template "#{name}/cell.rb.tt", "app/cells/#{global_namespace_path}/atom/#{name}_cell.rb"
    template "#{name}/cell.slim.tt", "app/cells/#{global_namespace_path}/atom/#{name}/show.slim"
    template "#{name}/cell_test.rb.tt", "test/cells/#{global_namespace_path}/atom/#{name}_cell_test.rb"

    root = File.expand_path("templates", __dir__)

    if File.exist?("#{root}/#{name}.coffee.tt")
      template "#{name}/#{name}.coffee.tt", "app/cells/#{global_namespace_path}/atom/#{name}/#{name}.coffee"
    end

    if File.exist?("#{root}/#{name}.sass.tt")
      template "#{name}/#{name}.sass.tt", "app/cells/#{global_namespace_path}/atom/#{name}/#{name}.sass"
    end

    add_atom_to_i18n_ymls(PREPARED_ATOMS[name.to_sym])
  end

  private
    def name
      super.downcase
    end
end
