# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/atom/atom_generator")

class Folio::MoleculeGenerator < Folio::AtomGenerator
  source_root File.expand_path("templates", __dir__)

  def atom_model
    template "atom_model.rb.tt", "app/models/#{application_namespace_path}/atom/#{name}.rb"
  end

  def cell
    if options[:cell]
      template "cell.rb.tt", "app/cells/#{application_namespace_path}/molecule/#{name}_cell.rb"
      template "cell.slim.tt", "app/cells/#{application_namespace_path}/molecule/#{name}/show.slim"
      template "cell_test.rb.tt", "test/cells/#{application_namespace_path}/molecule/#{name}_cell_test.rb"
    end
  end

  def component
    unless options[:cell]
      template "component.rb.tt", "app/components/#{application_namespace_path}/molecule/#{name}_component.rb"
      template "component.slim.tt", "app/components/#{application_namespace_path}/molecule/#{name}_component.slim"
      template "component_test.rb.tt", "test/components/#{application_namespace_path}/molecule/#{name}_component_test.rb"
    end
  end

  def molecule_css_class_name
    "#{classname_prefix}-molecule-#{dashed_resource_name}"
  end

  def molecule_component_name
    "#{application_namespace}::Molecule::#{class_name}Component"
  end
end
