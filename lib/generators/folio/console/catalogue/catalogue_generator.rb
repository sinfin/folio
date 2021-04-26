# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::Console::CatalogueGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("../templates", __FILE__)

  def index
    template "index.slim.tt", "app/views/folio/console/#{base_path}/index.slim"
  end

  def cell
    template "cell.rb.tt", "app/cells/folio/console/#{base_path}/catalogue_cell.rb"
    template "cell.slim.tt", "app/cells/folio/console/#{base_path}/catalogue/show.slim"
    template "cell_test.rb.tt", "test/cells/folio/console/#{base_path}/catalogue_cell_test.rb"
  end

  private
    def base_path
      class_name.underscore.pluralize
    end

    def index_variable_name
      class_name.split("::").pop.downcase.pluralize
    end

    def cell_name
      "folio/console/#{base_path}/catalogue"
    end

    def cell_css_class_name
      "f-c-#{classname_prefix}-#{plural_dashed_resource_name_without_namespace}-catalogue"
    end

    def plural_dashed_resource_name_without_namespace
      plural_dashed_resource_name.gsub("#{global_namespace_path}-", "")
    end

    def factory_name
      class_name.underscore.tr("/", "_")
    end
end
