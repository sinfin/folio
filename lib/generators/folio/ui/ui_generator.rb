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
    if name.blank? || CELLS.keys.exclude?(name.to_sym)
      raise UnknownCell, "Unknown cell #{name}. Allowed keys: #{CELLS.keys.join(', ')}"
    end

    if global_namespace == "Dummy"
      prefix = "test/dummy/"
    else
      prefix = ""
    end

    # template "#{name}/cell/cell.rb.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}_cell.rb"
    # template "#{name}/cell/cell.slim.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}/show.slim"
    # template "#{name}/cell/cell_test.rb.tt", "#{prefix}test/cells/#{global_namespace_path}/atom/#{name}_cell_test.rb"

    # root = File.expand_path("templates", __dir__)

    # if File.exist?("#{root}/#{name}/#{name}.coffee.tt")
    #   template "#{name}/#{name}.coffee.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}/#{name}.coffee"
    # end

    # if File.exist?("#{root}/#{name}/#{name}.sass.tt")
    #   template "#{name}/#{name}.sass.tt", "#{prefix}app/cells/#{global_namespace_path}/atom/#{name}/#{name}.sass"
    # end

    # add_atom_to_i18n_ymls(PREPARED_ATOMS[name.to_sym])
  end

  private
    def name
      super.downcase
    end
end
