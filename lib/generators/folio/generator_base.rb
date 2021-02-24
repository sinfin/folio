# frozen_string_literal: true

module Folio::GeneratorBase
  private
    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def plural_dashed_resource_name
      name.gsub(/[_\/]/, "-")
    end

    def dashed_resource_name
      model_resource_name.gsub("_", "-")
    end

    def atom_cell_name
      "#{global_namespace_path}/atom/#{name}"
    end

    def molecule_name
      class_name
    end

    def molecule_class_name
      "#{classname_prefix}-molecule-#{plural_dashed_resource_name}"
    end

    def molecule_cell_name
      "#{global_namespace_path}/molecule/#{name}"
    end

    def global_namespace_path
      global_namespace.underscore
    end

    def global_namespace
      Rails.application.class.name.deconstantize
    end

    def add_atom_to_i18n_ymls(values = {})
      I18n.available_locales.each do |locale|
        path = Rails.root.join("config/locales/atom.#{locale}.yml")
        i18n_key = "#{global_namespace_path}/atom/#{name}"
        i18n_value = values[locale] || values[:en] || name.capitalize

        new_hash = {
          locale.to_s => {
            "activerecord" => {
              "models" => {
                i18n_key => i18n_value
              }
            }
          }
        }

        if File.exist?(path)
          hash = YAML.load_file(path).deep_merge(new_hash)
          puts "Updating #{path}"
        else
          hash = new_hash
          puts "Creating #{path}"
        end

        # sort keys alphabetically
        sorted = hash[locale.to_s]["activerecord"]["models"].sort_by { |key, _v| key }
        hash[locale.to_s]["activerecord"]["models"] = Hash[ sorted ]

        File.open(path, "w") do |f|
          f.write hash.to_yaml
        end
      end
    end
end
