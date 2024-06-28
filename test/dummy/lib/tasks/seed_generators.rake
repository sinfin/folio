# frozen_string_literal: true

class Dummy::SeedGenerator
  def initialize(templates_path:)
    puts "I = identical, W = (over)write, M = missing\n"
    FileUtils.mkdir_p templates_path.to_s
    @templates_path = templates_path
  end

  def from_cell_path(cell_path)
    cell_basename = File.basename(cell_path)
    name = cell_basename.gsub("_cell.rb", "")

    template_cell_dir = @templates_path.join(name)
    FileUtils.mkdir_p template_cell_dir

    copy_file(cell_path, template_cell_dir.join("#{cell_basename}.tt"))

    FileUtils.mkdir_p template_cell_dir.join(name)
    Dir[Rails.root.join("app/cells/dummy/ui/#{name}/*")].each do |path|
      copy_file(path, template_cell_dir.join(name, "#{File.basename(path)}.tt"))
    end

    test_path = Rails.root.join("test/cells/dummy/ui/#{name}_cell_test.rb")
    if File.exist?(test_path)
      copy_file(test_path, template_cell_dir.join("#{name}_cell_test.rb.tt"))
    else
      puts "M #{relative_path(test_path)}"
    end
  end

  def from_component_path(component_path)
    name = component_path.split("app/components/dummy/ui/", 2)
                         .last
                         .gsub("_component.rb", "")

    template_component_dir = @templates_path.join(name)
    FileUtils.mkdir_p template_component_dir

    Dir[Rails.root.join("app/components/dummy/ui/#{name}_component.*")].each do |path|
      copy_file(path, template_component_dir.join("#{File.basename(path)}.tt"))
    end

    test_path = Rails.root.join("test/components/dummy/ui/#{name}_component_test.rb")
    if File.exist?(test_path)
      copy_file(test_path, template_component_dir.join("#{name}_component_test.rb.tt"))
    else
      puts "M #{relative_path(test_path)}"
    end
  end

  def from_atom_path(atom_path)
    name = atom_path.gsub(%r{.*app/models/dummy/atom/(.*).rb}, '\1')

    template_atom_dir = @templates_path.join(name)
    FileUtils.mkdir_p template_atom_dir

    copy_file(atom_path, template_atom_dir.join("#{File.basename(name)}.rb.tt"))

    template_atom_component_dir = template_atom_dir.join("component")

    FileUtils.mkdir_p template_atom_component_dir

    unless File.read(atom_path).include?("self.abstract_class = true")
      %w[atom molecule].each do |key|
        Dir[Rails.root.join("app/components/dummy/#{key}/#{name}_component.*")].each do |path|
          file_name = File.basename(path)
          copy_file(path, template_atom_dir.join("component/#{file_name}.tt"))
        end

        Dir[Rails.root.join("test/components/dummy/#{key}/#{name}_component_test.rb")].each do |path|
          copy_file(path, template_atom_dir.join("component/#{name}_component_test.rb.tt"))
        end
      end
    end

    i18n_values = {}

    Dir[Rails.root.join("config/locales/atom.*.yml")].each do |path|
      hash = YAML.load_file(path)
      locale = hash.keys.first
      i18n_values[locale] = {
        "activerecord" => {
          "attributes" => {
            "application_namespace_path/atom/#{name}" => hash[locale]["activerecord"]["attributes"]["dummy/atom/#{name}"],
          },
          "models" => {
            "application_namespace_path/atom/#{name}" => hash[locale]["activerecord"]["models"]["dummy/atom/#{name}"],
          },
        },
      }
    end

    i18n_yml = i18n_values.to_yaml(line_width: -1)
    i18n_path = template_atom_dir.join("i18n.yml")

    if File.exist?(i18n_path) && File.read(i18n_path) == i18n_yml
      puts "I #{relative_path(i18n_path)}"
    else
      File.write(i18n_path, i18n_yml)
      puts "W #{relative_path(i18n_path)}"
    end
  end

  def blog
    scaffold("blog")
  end

  def search
    scaffold("searches")
  end

  def install
    Dir[Rails.root.join("app/controllers/application_controller.rb"),
        Rails.root.join("app/lib/application_component.rb"),
        Rails.root.join("app/lib/dummy/cache_keys.rb"),
        Rails.root.join("app/lib/dummy/current_methods.rb")].each do |path|
      copy_file(path, @templates_path.join("#{relative_application_path(path).gsub('dummy', 'application_namespace_path')}.tt"))
    end

    Dir[Folio::Engine.root.join(".editorconfig")].each do |path|
      copy_file(path, @templates_path.join(relative_path(path)))
    end
  end

  def mailer
    scaffold("mailer")

    Dir[Rails.root.join("app/assets/stylesheets/dummy/mailer/**/*.sass"),
        Rails.root.join("app/assets/stylesheets/dummy/mailer_extras/**/*.sass"),
        Rails.root.join("app/assets/stylesheets/dummy/mailer*.sass")].each do |path|
      target_path = "#{relative_application_path(path).gsub('dummy', 'application_namespace_path')}.tt"
      copy_file(path, @templates_path.join(target_path))
    end

    copy_file(Folio::Engine.root.join("app/views/layouts/folio/mailer.html.slim"),
              @templates_path.join("app/views/layouts/folio/mailer.html.slim.tt"))

    ui_i18n_yamls(Rails.root.join("config/locales/dummy/mailer*.yml"))
  end

  def ui_i18n_yamls(path)
    Dir[path].each do |yaml_path|
      hash = YAML.load_file(yaml_path)
      replaced = hash[hash.keys.first]["dummy"]["ui"].to_yaml(line_width: -1)
      yaml_to = @templates_path.join("#{File.basename(yaml_path)}")

      if File.exist?(yaml_to) && File.read(yaml_to) == replaced
        puts "I #{relative_path(yaml_to)}"
      else
        File.write(yaml_to, replaced)
        puts "W #{relative_path(yaml_to)}"
      end
    end
  end

  def atoms_controllers(path)
    copy_file(path, @templates_path.join("atoms_controller.rb.tt"))

    copy_file(Rails.root.join("data/atoms_showcase.yml"), @templates_path.join("data/atoms_showcase.yml.tt"))

    Dir[Rails.root.join("app/views/dummy/atoms/show.slim")].each do |path|
      name = File.basename(path)
      copy_file(path, @templates_path.join("#{name}.tt"))
    end
  end

  def ui_controllers(path)
    copy_file(path, @templates_path.join("ui_controller.rb.tt"))

    Dir[Rails.root.join("app/views/dummy/ui/*.slim")].each do |path|
      name = File.basename(path)
      copy_file(path, @templates_path.join("views/#{name}.tt"))
    end
  end

  def ui_helper(path)
    copy_file(path, @templates_path.join("ui_helper.rb.tt"))
  end

  def ui_routes(path)
    copy_file(path, @templates_path.join("ui-routes.rb.tt"))
  end

  def copy_file(from, to)
    text = File.read(from)

    replaced = if to.to_s.include?("public/")
      text
    else
      replace_names(text)
    end

    if File.exist?(to) && File.read(to) == replaced
      puts "I #{relative_path(to)}"
    else
      FileUtils.mkdir_p File.dirname(to)
      File.write(to, replaced)
      puts "W #{relative_path(to)}"
    end
  end

  private
    def root
      Folio::Engine.root.to_s
    end

    def relative_path(path)
      path.to_s.gsub(%r{\A#{root}/}, "")
    end

    def application_root
      Rails.root.to_s
    end

    def relative_application_path(path)
      path.to_s.gsub(%r{\A#{application_root}/}, "")
    end

    def replace_names(str)
      str.gsub("Dummy::", "<%= application_namespace %>::")
         .gsub("dummy_", "<%= application_namespace_path %>_")
         .gsub("dummy.search", "<%= application_namespace_path %>.search")
         .gsub("dummy_search", "<%= application_namespace_path %>_search")
         .gsub("dummy_ui_", "<%= application_namespace_path %>_ui_")
         .gsub("dummy_atoms_", "<%= application_namespace_path %>_atoms_")
         .gsub("dummy:", "<%= application_namespace_path %>:")
         .gsub(":dummy", ":<%= application_namespace_path %>")
         .gsub("--dummy-", "--<%= application_namespace_path %>-")
         .gsub("window.dummy", "window.<%= application_namespace_path %>")
         .gsub("window.Dummy", "window.<%= application_namespace %>")
         .gsub("d-ui", "<%= classname_prefix %>-ui")
         .gsub("d-atoms", "<%= classname_prefix %>-atoms")
         .gsub("d-unlink", "<%= classname_prefix %>-unlink")
         .gsub("d-atom", "<%= classname_prefix %>-atom")
         .gsub("d-blog", "<%= classname_prefix %>-blog")
         .gsub("d-search", "<%= classname_prefix %>-search")
         .gsub("d-mailer", "<%= classname_prefix %>-mailer")
         .gsub("d-molecule", "<%= classname_prefix %>-molecule")
         .gsub("d-rich-text", "<%= classname_prefix %>-rich-text")
         .gsub("d-with-icon", "<%= classname_prefix %>-with-icon")
         .gsub("dAtom", "<%= classname_prefix %>Atom")
         .gsub("dSearch", "<%= classname_prefix %>Search")
         .gsub("cells/dummy", "cells/<%= application_namespace_path %>")
         .gsub("components/dummy", "components/<%= application_namespace_path %>")
         .gsub("dummy/ui", "<%= application_namespace_path %>/ui")
         .gsub("dummy/blog", "<%= application_namespace_path %>/blog")
         .gsub("dummy/search", "<%= application_namespace_path %>/search")
         .gsub("dummy/mailer", "<%= application_namespace_path %>/mailer")
         .gsub("dummy/atom", "<%= application_namespace_path %>/atom")
         .gsub("dummy/molecule", "<%= application_namespace_path %>/molecule")
         .gsub("dummy_menu", "<%= application_namespace_path %>_menu")
    end

    def scaffold(key)
      Dir[Rails.root.join("app/cells/**/dummy/#{key}/**/*.*"),
          Rails.root.join("app/cells/**/dummy/*/#{key}/**/*.*"),
          Rails.root.join("app/components/**/dummy/#{key}/**/*.*"),
          Rails.root.join("app/components/**/dummy/*/#{key}/**/*.*"),
          Rails.root.join("app/controllers/**/dummy/#{key}/**/*.rb"),
          Rails.root.join("app/controllers/**/dummy/#{key}_controller.rb"),
          Rails.root.join("app/models/dummy/#{key}/**/*.rb"),
          Rails.root.join("app/models/dummy/atom/#{key}/**/*.rb"),
          Rails.root.join("app/models/dummy/#{key}.rb"),
          Rails.root.join("app/views/dummy/#{key}/**/*.slim"),
          Rails.root.join("app/views/folio/console/dummy/#{key}/**/*.slim"),
          Rails.root.join("config/locales/#{key}.*.yml"),
          Rails.root.join("db/migrate/*_create_#{key}.rb"),
          Rails.root.join("test/**/dummy/#{key}/**/*.rb"),
          Rails.root.join("test/**/dummy/#{key}_controller_test.rb"),
          Rails.root.join("test/**/dummy/*/#{key}/**/*.rb")].each do |path|
        target_path = "#{relative_application_path(path).gsub('dummy', 'application_namespace_path')}.tt"
        copy_file(path, @templates_path.join(target_path))
      end
    end
end

namespace :dummy do
  namespace :seed_generators do
    task all: :environment do
      Rake::Task["dummy:seed_generators:install"].invoke
      Rake::Task["dummy:seed_generators:assets"].invoke
      Rake::Task["dummy:seed_generators:ui"].invoke
      Rake::Task["dummy:seed_generators:prepared_atom"].invoke
      Rake::Task["dummy:seed_generators:blog"].invoke
      Rake::Task["dummy:seed_generators:search"].invoke
      Rake::Task["dummy:seed_generators:mailer"].invoke
    end

    task assets: :environment do
      require "generators/folio/assets/assets_generator"

      templates_path = Folio::Engine.root.join("lib/generators/folio/assets/templates")
      gen = Dummy::SeedGenerator.new(templates_path:)

      {
        Folio::AssetsGenerator::TEMPLATES => ".tt",
        ["app/assets/stylesheets/modules/bootstrap-overrides/**/*.sass"] => ".tt",
        Folio::AssetsGenerator::FILES => "",
      }.each do |paths, affix|
        paths.each do |path|
          Dir[Rails.root.join(path)].each do |glob_path|
            next if File.directory?(glob_path)

            path = glob_path.to_s.gsub(%r{\A#{Folio::Engine.root}/test/dummy/}, "")
            gen.copy_file(glob_path, templates_path.join("#{path}#{affix}"))
          end
        end
      end
    end

    task ui: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/ui/templates"))

      Dir[Rails.root.join("app/cells/dummy/ui/**/*_cell.rb")].each do |cell_path|
        gen.from_cell_path(cell_path)
      end

      Dir[Rails.root.join("app/components/dummy/ui/**/*_component.rb")].each do |component_path|
        gen.from_component_path(component_path)
      end

      gen.ui_i18n_yamls(Rails.root.join("config/locales/ui.*.yml"))

      gen.ui_controllers(Rails.root.join("app/controllers/dummy/ui_controller.rb"))

      gen.ui_helper(Rails.root.join("app/helpers/dummy/ui_helper.rb"))

      gen.ui_routes(Rails.root.join("config/routes/dummy/ui.rb"))
    end

    task prepared_atom: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/prepared_atom/templates"))

      Dir[Rails.root.join("app/models/dummy/atom/**/*.rb")].each do |atom_path|
        next if atom_path.include?("/blog/")

        gen.from_atom_path(atom_path)
      end

      gen.atoms_controllers(Rails.root.join("app/controllers/dummy/atoms_controller.rb"))
    end

    task blog: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/blog/templates"))
      gen.blog
    end

    task search: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/search/templates"))
      gen.search
    end

    task mailer: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/mailer/templates"))
      gen.mailer
    end

    task install: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/templates"))
      gen.install
    end
  end
end
