# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::AtomGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  class_option :cell, type: :boolean, default: false

  source_root File.expand_path("templates", __dir__)

  def atom_model
    template "atom_model.rb.tt", "#{pack_path_prefix}app/models/#{application_namespace_path}/atom/#{name}.rb"
  end

  def cell
    if options[:cell]
      template "cell.rb.tt", "#{pack_path_prefix}app/cells/#{application_namespace_path}/atom/#{name}_cell.rb"
      template "cell.slim.tt", "#{pack_path_prefix}app/cells/#{application_namespace_path}/atom/#{name}/show.slim"
      template "cell_test.rb.tt", "#{pack_path_prefix}test/cells/#{application_namespace_path}/atom/#{name}_cell_test.rb"
    end
  end

  def component
    unless options[:cell]
      template "component.rb.tt", "#{pack_path_prefix}app/components/#{application_namespace_path}/atom/#{name}_component.rb"
      template "component.slim.tt", "#{pack_path_prefix}app/components/#{application_namespace_path}/atom/#{name}_component.slim"
      template "component_test.rb.tt", "#{pack_path_prefix}test/components/#{application_namespace_path}/atom/#{name}_component_test.rb"
    end
  end

  def atom_css_class_name
    "#{classname_prefix}-atom-#{dashed_resource_name}"
  end

  def atom_component_name
    "#{application_namespace}::Atom::#{class_name}Component"
  end

  def i18n_yml
    add_atom_to_i18n_ymls
  end
end
