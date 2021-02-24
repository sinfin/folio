# frozen_string_literal: true

class Folio::PreparedAtomGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  PREPARED_ATOMS = %w[
    text
    title
  ]

  class UnknownAtomKey < StandardError; end

  def create
    if name.blank? || PREPARED_ATOMS.exclude?(name)
      raise UnknownAtomKey, "Unknown atom key #{name}. Allowed keys: #{PREPARED_ATOMS.join(', ')}"
    end

    template "#{name}/atom_model.rb.tt", "app/models/#{global_namespace_path}/atom/#{name}.rb"
    template "#{name}/cell.rb.tt", "app/cells/#{global_namespace_path}/atom/#{name}_cell.rb"
    template "#{name}/cell.slim.tt", "app/cells/#{global_namespace_path}/atom/#{name}/show.slim"
    template "#{name}/cell_test.rb.tt", "test/cells/#{global_namespace_path}/atom/#{name}_cell_test.rb"

    root = File.expand_path("templates", __dir__)

    if File.exist?("#{root}/#{name}.coffee.tt")
      template "#{name}/#{name}.coffee.tt", "app/cells/#{global_namespace_path}/atom/#{name}/#{name}.coffee"
    end

    if File.exist?("#{root}/#{name}.sass.tt")
      template "#{name}/#{name}.sass.tt", "app/cells/#{global_namespace_path}/atom/#{name}/#{name}.sass"
    end
  end

  private
    def name
      super.downcase
    end

    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def dashed_resource_name
      model_resource_name.gsub("_", "-")
    end

    def atom_cell_name
      "#{global_namespace_path}/atom/#{name}"
    end

    def global_namespace_path
      global_namespace.underscore
    end

    def global_namespace
      Rails.application.class.name.deconstantize
    end
end
