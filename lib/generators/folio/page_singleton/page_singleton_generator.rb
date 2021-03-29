# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::PageSingletonGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  desc "Creates a page singleton and a yaml seed"

  source_root File.expand_path("templates", __dir__)

  def copy_templates
    [
      "app/models/global_namespace_path/page/file_name.rb",
      "data/seed/pages/file_name.yml",
    ].each do |f|
      template "#{f}.tt", f.gsub("file_name", file_name).gsub("global_namespace_path", global_namespace_path)
    end
  end

  private
    def file_name
      name.underscore
    end
end
