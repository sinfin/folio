# frozen_string_literal: true

module Folio::GeneratorBase
  private
    def atom_name
      @atom_name || name
    end

    def classname_prefix
      Rails.application.class.name[0].downcase
    end

    def plural_dashed_resource_name
      dashed_resource_name.pluralize
    end

    def dashed_resource_name
      model_resource_name.gsub("_", "-").gsub("::", "-")
    end

    def atom_cell_name
      "#{global_namespace_path}/atom/#{atom_name}"
    end

    def molecule_name
      class_name
    end

    def molecule_class_name
      "#{classname_prefix}-molecule-#{plural_dashed_resource_name}"
    end

    def molecule_cell_name
      "#{global_namespace_path}/molecule/#{atom_name}"
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
        i18n_key = "#{global_namespace_path}/atom/#{atom_name}"
        i18n_value = values[locale] || values[locale.to_s] || values[:en]

        if i18n_value.is_a?(Hash)
          new_hash = { locale.to_s => i18n_value }
        else
          new_hash = {
            locale.to_s => {
              "activerecord" => {
                "models" => {
                  i18n_key => i18n_value || atom_name
                }
              }
            }
          }
        end

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
          f.write hash.to_yaml(line_width: -1)
        end
      end
    end
end
