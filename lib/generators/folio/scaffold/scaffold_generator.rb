# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::ScaffoldGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def copy_templates
    base = ::Folio::Engine.root.join("lib/generators/folio/scaffold/templates/").to_s

    Dir["#{base}/**/*.tt"].each do |full_template_path|
      template_path = full_template_path.gsub("#{base}/", "")
      target_path = template_path.delete_suffix(".tt")

      # keep order!
      %w[
        namespace_path_base
        namespace_path
        plural_element_name
      ].each do |key|
        target_path = target_path.gsub(key, send(key))
      end

      template template_path, target_path
    end
  end

  def plural_model_resource_name
    @plural_model_resource_name ||= model_resource_name.pluralize
  end

  def namespace_path
    @namespace_path ||= class_name.constantize.model_name.collection
  end

  def namespace_path_base
    @namespace_path_base ||= namespace_path.split("/")[0..-2].join("/")
  end

  def controller_name
    "#{class_name.pluralize}Controller"
  end

  def plural_element_name
    @plural_element_name ||= element_name.pluralize
  end

  def element_name
    @element_name ||= class_name.constantize.model_name.element
  end

  def class_name_spacing
    class_name.gsub(/./, " ")
  end

  def cell_class_name
    @cell_class_name ||= "#{classname_prefix}-#{class_name.demodulize.underscore.pluralize.dasherize}-show-header"
  end
end
