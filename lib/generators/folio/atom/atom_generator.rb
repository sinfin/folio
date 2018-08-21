# frozen_string_literal: true

class Folio::AtomGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def atom_model
    template 'atom_model.rb.tt', "app/models/atom/#{file_name}.rb"
  end

  def cell
    template 'cell.rb.tt', "app/cells/atom/#{file_name}_cell.rb"
    template 'cell.slim.tt', "app/cells/atom/#{file_name}/show.slim"
    template 'cell_test.rb.tt', "test/cells/atom/#{file_name}_cell_test.rb"
  end

  private

    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def dashed_resource_name
      model_resource_name.gsub('_', '-')
    end
end
