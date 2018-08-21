# frozen_string_literal: true

class Folio::MoleculeGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def cell
    template 'cell.rb.tt', "app/cells/molecule/#{plural_route_name}_cell.rb"
    template 'cell_test.rb.tt', "test/cells/molecule/#{plural_route_name}_cell_test.rb"
    template 'cell.slim.tt', "app/cells/molecule/#{plural_route_name}/show.slim"
  end

  def update_atom
    atom_path = "app/models/atom/#{model_resource_name}.rb"

    if File.exists? Rails.root.join(atom_path)
      inject_into_file atom_path, before: %{end

# == Schema Information} do %{
  def self.molecule_cell_name
    'molecule/#{plural_table_name}'
  end
}
      end
    end
  end

  private

    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def dashed_resource_name
      plural_table_name.gsub('_', '-')
    end

    def molecule_name
      plural_name.camelize
    end
end
