# frozen_string_literal: true

require 'rails/generators/erb/scaffold/scaffold_generator'

class Folio::Console::ScaffoldGenerator < Erb::Generators::ScaffoldGenerator
  source_root File.expand_path('../templates', __FILE__)

  hook_for :orm, as: :scaffold
  hook_for :form_builder, as: :scaffold

  def copy_view_files
    available_views.each do |view|
      filename = filename_with_extensions(view).gsub('.html', '')
      template "#{view}.slim", File.join('app', 'views', 'folio', 'console', controller_file_path, filename)
    end
    template '_table_row.slim', File.join('app', 'views', 'folio', 'console', controller_file_path, "_#{singular_table_name}.slim")
  end

  def copy_controller
    template 'controller.rb.tt', File.join('app', 'controllers', 'folio', 'console', "#{controller_file_path}_controller.rb")
  end

  def index_resource_name
    "main_app.console_#{plural_table_name}_path"
  end

  def update_resource_name
    "main_app.console_#{singular_table_name}_path(@#{singular_table_name}.id)"
  end

  def delete_resource_name_no_at
    "main_app.console_#{singular_table_name}_path(#{singular_table_name}.id)"
  end

  def new_resource_name
    "main_app.new_console_#{singular_table_name}_path"
  end

  def edit_resource_name
    "main_app.edit_console_#{singular_table_name}_path"
  end

  def redirect_resource_name
    edit_resource_name
  end

  def positionable?
    attributes_names.include?('position')
  end

  def has_attachmentable?
    class_name.constantize.respond_to?(:cover_placement)
  end

  def form_tabs
    base = [:content]
    base << :gallery if has_attachmentable?
    base
  end

  def index_scope
    positionable? ? '.ordered' : ''
  end

  protected

    def available_views
      ['index', 'edit', 'new', '_form']
    end

    def handler
      :slim
    end

    def attributes_names
      super.presence || fallback_attributes_names
    end

    def fallback_attributes_names
      klass = class_name.constantize
      klass.attribute_names - ['id', 'created_at', 'updated_at']
    end
end
