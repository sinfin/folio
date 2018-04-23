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
  end

  def copy_controller
    template 'controller.rb.tt', File.join('app', 'controllers', 'folio', 'console', "#{controller_file_path}_controller.rb")
  end

  def index_resource_name
    "main_app.console_#{plural_table_name}_path"
  end

  def redirect_resource_name
    "main_app.edit_console_#{singular_table_name}_path"
  end

  protected

    def available_views
      ['index', 'edit', 'new', '_form']
    end

    def handler
      :slim
    end
end
