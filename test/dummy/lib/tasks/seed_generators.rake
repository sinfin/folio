# frozen_string_literal: true

class Dummy::SeedGenerator
  def initialize(templates_path:)
    puts "I = identical, W = (over)write, M = missing\n"
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

  def from_atom_path(atom_path)
    name = atom_path.gsub(%r{.*app/models/dummy/atom/(.*).rb}, '\1')

    template_atom_dir = @templates_path.join(name)
    FileUtils.mkdir_p template_atom_dir

    copy_file(atom_path, template_atom_dir.join("#{name}.rb.tt"))

    template_atom_cell_dir = template_atom_dir.join("cell")

    FileUtils.mkdir_p template_atom_cell_dir

    unless File.read(atom_path).include?("self.abstract_class = true")
      %w[atom molecule].each do |key|
        Dir[Rails.root.join("app/cells/dummy/#{key}/#{name}_cell.rb")].each do |path|
          copy_file(path, template_atom_dir.join("cell/#{name}_cell.rb.tt"))
        end

        Dir[Rails.root.join("app/cells/dummy/#{key}/#{name}/*")].each do |path|
          copy_file(path, template_atom_cell_dir.join(name, "#{File.basename(path)}.tt"))
        end

        Dir[Rails.root.join("test/cells/dummy/#{key}/#{name}_cell_test.rb")].each do |path|
          copy_file(path, template_atom_dir.join("cell/#{name}_cell_test.rb.tt"))
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
        }
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
    Dir[Rails.root.join("app/controllers/**/dummy/blog/**/*.rb"),
        Rails.root.join("app/models/dummy/blog/**/*.rb"),
        Rails.root.join("app/models/dummy/blog.rb"),
        Rails.root.join("app/views/dummy/blog/**/*.slim"),
        Rails.root.join("app/views/folio/console/dummy/blog/**/*.slim"),
        Rails.root.join("config/locales/blog.*.yml"),
        Rails.root.join("db/migrate/*_create_blog.rb"),
        Rails.root.join("test/**/dummy/blog/**/*.rb"),].each do |path|
      target_path = "#{relative_application_path(path).gsub('dummy', "application_namespace_path")}.tt"
      copy_file(path, @templates_path.join(target_path))
    end
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

  private
    def root
      Folio::Engine.root.to_s
    end

    def relative_path(path)
      path.to_s.gsub(/\A#{root}\//, "")
    end

    def application_root
      Rails.root.to_s
    end

    def relative_application_path(path)
      path.to_s.gsub(/\A#{application_root}\//, "")
    end

    def replace_names(str)
      str.gsub("Dummy::", "<%= application_namespace %>::")
         .gsub("dummy_", "<%= application_namespace_path %>_")
         .gsub("d-ui", "<%= classname_prefix %>-ui")
         .gsub("d-atom", "<%= classname_prefix %>-atom")
         .gsub("d-molecule", "<%= classname_prefix %>-molecule")
         .gsub("d-rich-text", "<%= classname_prefix %>-rich-text")
         .gsub("d-with-icon", "<%= classname_prefix %>-with-icon")
         .gsub("dAtom", "<%= classname_prefix %>Atom")
         .gsub("dummy/ui", "<%= application_namespace_path %>/ui")
         .gsub("dummy/blog", "<%= application_namespace_path %>/blog")
         .gsub("dummy_menu", "<%= application_namespace_path %>_menu")
         .gsub(%r{dummy/atom/[\w/]+}, "<%= atom_cell_name %>")
         .gsub(%r{"dummy/molecule/.*"}, '"<%= molecule_cell_name %>"')
    end

    def copy_file(from, to)
      text = File.read(from)
      replaced = replace_names(text)

      if File.exist?(to) && File.read(to) == replaced
        puts "I #{relative_path(to)}"
      else
        FileUtils.mkdir_p File.dirname(to)
        File.write(to, replaced)
        puts "W #{relative_path(to)}"
      end
    end
end

namespace :dummy do
  namespace :seed_generators do
    task all: :environment do
      Rake::Task["dummy:seed_generators:ui"].invoke
      Rake::Task["dummy:seed_generators:prepared_atom"].invoke
      Rake::Task["dummy:seed_generators:blog"].invoke
    end

    task ui: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/ui/templates"))

      Dir[Rails.root.join("app/cells/dummy/ui/**/*_cell.rb")].each do |cell_path|
        gen.from_cell_path(cell_path)
      end

      gen.ui_i18n_yamls(Rails.root.join("config/locales/ui.*.yml"))
    end

    task prepared_atom: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/prepared_atom/templates"))

      Dir[Rails.root.join("app/models/dummy/atom/**/*.rb")].each do |atom_path|
        gen.from_atom_path(atom_path)
      end
    end

    task blog: :environment do
      gen = Dummy::SeedGenerator.new(templates_path: Folio::Engine.root.join("lib/generators/folio/blog/templates"))
      gen.blog
    end
  end
end
