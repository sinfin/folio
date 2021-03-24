# frozen_string_literal: true

namespace :dummy do
  task ui_cells_to_templates: :environment do
    puts "I = identical, W = (over)write, M = missing\n"

    root = Folio::Engine.root.to_s

    templates_path = Folio::Engine.root.join('lib/generators/folio/ui/templates')

    relative_path = Proc.new do |path|
      path.to_s.gsub(/\A#{root}\//, '')
    end

    replace_names = Proc.new do |str|
      str.gsub("Dummy::", "<%= global_namespace %>::")
         .gsub("d-ui-", "<%= classname_prefix %>-ui-")
         .gsub("dummy/ui", "<%= global_namespace_path %>/ui")
    end

    copy_file = Proc.new do |from, to|
      text = File.read(from)
      replaced = replace_names.call(text)

      if File.exists?(to) && File.read(to) == replaced
        puts "I #{relative_path.call(to)}"
      else
        File.write(to, replaced)
        puts "W #{relative_path.call(to)}"
      end
    end

    Dir[Rails.root.join('app/cells/dummy/ui/**/*_cell.rb')].each do |cell_path|
      cell_basename = File.basename(cell_path)
      name = cell_basename.gsub('_cell.rb', '')

      template_cell_dir = templates_path.join(name)
      FileUtils.mkdir_p template_cell_dir

      copy_file.call(cell_path, template_cell_dir.join("#{cell_basename}.tt"))

      FileUtils.mkdir_p template_cell_dir.join(name)
      Dir[Rails.root.join("app/cells/dummy/ui/#{name}/*")].each do |path|
        copy_file.call(path, template_cell_dir.join(name, "#{File.basename(path)}.tt"))
      end

      test_path = Rails.root.join("test/cells/dummy/ui/#{name}_cell_test.rb")
      if File.exists?(test_path)
        copy_file.call(test_path, template_cell_dir.join("#{name}_cell_test.rb.tt"))
      else
        puts "M #{relative_path.call(test_path)}"
      end
    end

    Dir[Rails.root.join('config/locales/ui.*.yml')].each do |yaml_path|
      text = File.read(yaml_path)
      replaced = text.gsub('dummy:', '<%= global_namespace_path %>')
      yaml_to = templates_path.join("#{File.basename(yaml_path)}.tt")

      if File.exists?(yaml_to) && File.read(yaml_to) == replaced
        puts "I #{relative_path.call(yaml_to)}"
      else
        File.write(yaml_to, replaced)
        puts "W #{relative_path.call(yaml_to)}"
      end
    end
  end
end
