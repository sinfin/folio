# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::PageSingletonGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  desc "Creates a page singleton and a yaml seed"

  source_root File.expand_path("templates", __dir__)

  def copy_templates
    [
      "app/models/application_namespace_path/page/file_name.rb",
      "data/seed/pages/file_name.yml",
    ].each do |f|
      template "#{f}.tt", f.gsub("file_name", file_name).gsub("application_namespace_path", application_namespace_path)
    end
  end

  def add_to_i18n
    I18n.available_locales.each do |locale|
      path = Rails.root.join("config/locales/page.#{locale}.yml")
      i18n_key = "#{application_namespace_path}/page/#{name}"
      page_label = locale == :cs ? "Stránka" : "Page"

      new_hash = {
        locale.to_s => {
          "activerecord" => {
            "models" => {
              i18n_key => "#{page_label} / #{class_name}"
            }
          }
        }
      }

      if File.exist?(path)
        hash = new_hash.deep_merge(YAML.load_file(path))
        puts "Updating #{path}"
      else
        hash = new_hash
        puts "Creating #{path}"
      end

      # sort keys alphabetically
      if hash[locale.to_s]["activerecord"]["models"]
        sorted = hash[locale.to_s]["activerecord"]["models"].sort_by { |key, _v| key }
        hash[locale.to_s]["activerecord"]["models"] = Hash[ sorted ]
      end

      if hash[locale.to_s]["activerecord"]
        sorted = hash[locale.to_s]["activerecord"].sort_by { |key, _v| key }
        hash[locale.to_s]["activerecord"] = Hash[ sorted ]
      end

      File.open(path, "w") do |f|
        f.write hash.to_yaml(line_width: -1)
      end
    end
  end

  private
    def file_name
      name.underscore
    end
end
