# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::ComponentGenerator < Rails::Generators::NamedBase
  include ::Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def component
    template "component.rb.tt", "app/components/#{component_name}_component.rb"
    template "component.slim.tt", "app/components/#{component_name}_component.slim"
    template "component_test.rb.tt", "test/components/#{component_name}_component_test.rb"
  end

  private
    def component_name
      if name.start_with?("/")
        name
      else
        "#{application_namespace_path}/#{name}"
      end
    end

    def component_class_name
      "#{application_namespace}::#{class_name}Component"
    end

    def css_class_name
      "#{classname_prefix}-#{class_name.underscore.tr('/', '-').tr('_', '-')}"
    end
end
