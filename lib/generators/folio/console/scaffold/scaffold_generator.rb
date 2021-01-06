# frozen_string_literal: true

require "rails/generators/erb/scaffold/scaffold_generator"

class Folio::Console::ScaffoldGenerator < Erb::Generators::ScaffoldGenerator
  source_root File.expand_path("../templates", __FILE__)

  hook_for :orm, as: :scaffold
  hook_for :form_builder, as: :scaffold

  def copy_view_files
    available_views.each do |view|
      filename = filename_with_extensions(view).gsub(".html", "")
      template "#{view}.slim", File.join("app/views/folio/console", controller_file_path, filename)
    end
  end

  def copy_controller
    template "controller.rb.tt", File.join("app/controllers/folio/console", "#{controller_file_path}_controller.rb")
  end

  def copy_controller_test
    template "controller_test.rb.tt", File.join("test/controllers/folio/console", "#{controller_file_path}_controller_test.rb")
  end

  def positionable?
    attributes_names.include?("position")
  end

  def has_attachmentable?
    class_name.constantize.method_defined?(:cover_placement)
  end

  def has_atoms?
    class_name.constantize.method_defined?(:atoms)
  end

  def filterable?
    class_name.constantize.method_defined?(:filter_by_params)
  end

  def form_tabs
    base = [:content]
    base
  end

  def index_scope
    positionable? ? ".ordered" : ".order(id: :desc)"
  end

  def instance_variable_name(plural: false)
    base = controller_file_path.split("/").last
    if plural
      base
    else
      base.singularize
    end
  end

  protected
    def available_views
      ["index", "edit", "new", "_form"]
    end

    def handler
      :slim
    end

    def class_name
      super.gsub("Folio::Folio::", "Folio::")
    end

    def attributes_names
      super.presence || fallback_attributes_names
    end

    def fallback_attributes_names
      klass = class_name.constantize
      klass.attribute_names - ["id", "created_at", "updated_at"]
    end

    def form_attribute_names
      attributes_names - ["position"]
    end

    def attribute_inputs
      spacer = has_attachmentable? ? "\n        " : "\n    "
      form_attribute_names.map { |name| attribute_input(name) }.join(spacer)
    end

    def attribute_input(name)
      if /_id$/.match?(name)
        "= f.association :#{name.gsub(/_id$/, '')}"
      else
        "= f.input :#{name}"
      end
    end
end
