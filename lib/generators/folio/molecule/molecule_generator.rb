# frozen_string_literal: true

class Folio::MoleculeGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def atom_model
    template 'atom_model.rb.tt', "app/models/#{global_namespace_path}/atom/#{file_name}.rb"
  end

  def cell
    template 'cell.rb.tt', "app/cells/#{global_namespace_path}/molecule/#{plural_name}_cell.rb"
    template 'cell.slim.tt', "app/cells/#{global_namespace_path}/molecule/#{plural_name}/show.slim"
    template 'cell_test.rb.tt', "test/cells/#{global_namespace_path}/molecule/#{plural_name}_cell_test.rb"
  end

  private

    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def plural_dashed_resource_name
      plural_name.gsub('_', '-')
    end

    def dashed_resource_name
      model_resource_name.gsub('_', '-')
    end

    def molecule_name
      class_name.pluralize
    end

    def molecule_class_name
      "#{classname_prefix}-molecule-#{plural_dashed_resource_name}"
    end

    def molecule_cell_name
      "#{global_namespace_path}/molecule/#{plural_name}"
    end

    def global_namespace_path
      global_namespace.underscore
    end

    def global_namespace
      Rails.application.class.name.deconstantize
    end
end
