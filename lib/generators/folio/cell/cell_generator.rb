# frozen_string_literal: true

class Folio::CellGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def cell
    template 'cell.rb.tt', "app/cells/#{cell_name}_cell.rb"
    template 'cell.slim.tt', "app/cells/#{cell_name}/show.slim"
    template 'cell_test.rb.tt', "test/cells/#{cell_name}_cell_test.rb"
  end

  private

    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def model_resource_name
      super.gsub(/\A_/, '')
    end

    def class_name
      super.gsub(/\A::/, '')
    end

    def dashed_resource_name
      model_resource_name.gsub('_', '-')
    end

    def cell_name
      "#{global_namespace_path}#{name.gsub(/\A\//, '')}"
    end

    def global_namespace_path
      global_namespace.underscore
    end

    def global_namespace
      if name.start_with?('/')
        ''
      else
        "#{Rails.application.class.name.deconstantize}::"
      end
    end
end
