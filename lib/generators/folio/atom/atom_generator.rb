# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::AtomGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def atom_model
    template "atom_model.rb.tt", "app/models/#{global_namespace_path}/atom/#{name}.rb"
  end

  def cell
    template "cell.rb.tt", "app/cells/#{global_namespace_path}/atom/#{name}_cell.rb"
    template "cell.slim.tt", "app/cells/#{global_namespace_path}/atom/#{name}/show.slim"
    template "cell_test.rb.tt", "test/cells/#{global_namespace_path}/atom/#{name}_cell_test.rb"
  end

  def i18n_yml
    add_atom_to_i18n_ymls
  end
end
