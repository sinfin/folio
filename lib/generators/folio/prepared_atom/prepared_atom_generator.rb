# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::PreparedAtomGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  PREPARED_ATOMS = {
    text: {
      cs: {
        name: "Text (odstavce, tabulky, apod.)",
        attributes: {},
      },
      en: {
        name: "Text (paragraphs, tables, etc.)",
        attributes: {},
      },
    },
    title: {
      cs: {
        name: "Nadpis",
        attributes: {},
      },
      en: {
        name: "Title",
        attributes: {},
      },
    },
    images: {
      cs: {
        name: "Obrázky (galerie)",
        attributes: {
          same_width: "Zarovnat do mřížky",
          title: "Popisek pod galerií",
        },
      },
      en: {
        name: "Images (gallery)",
        attributes: {
          same_width: "Align to grid",
          title: "Caption under the gallery",
        },
      },
    }
  }

  class UnknownAtomKey < StandardError; end

  def create
    if name.blank? || PREPARED_ATOMS.keys.exclude?(name.to_sym)
      raise UnknownAtomKey, "Unknown atom key #{name}. Allowed keys: #{PREPARED_ATOMS.keys.join(', ')}"
    end

    if global_namespace == "Dummy"
      prefix = "test/dummy/"
    else
      prefix = ""
    end


    template "#{name}/atom_model.rb.tt", "#{prefix}app/models/#{global_namespace_path}/atom/#{name}.rb"
    template "#{name}/cell.rb.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}_cell.rb"
    template "#{name}/cell.slim.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}/show.slim"
    template "#{name}/cell_test.rb.tt", "#{prefix}test/cells/#{global_namespace_path}/atom/#{name}_cell_test.rb"

    root = File.expand_path("templates", __dir__)

    if File.exist?("#{root}/#{name}/#{name}.coffee.tt")
      template "#{name}/#{name}.coffee.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}/#{name}.coffee"
    end

    if File.exist?("#{root}/#{name}/#{name}.sass.tt")
      template "#{name}/#{name}.sass.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}/#{name}.sass"
    end

    add_atom_to_i18n_ymls(PREPARED_ATOMS[name.to_sym])
  end

  private
    def name
      super.downcase
    end
end
