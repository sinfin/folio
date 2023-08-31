# frozen_string_literal: true

module Folio::GeneratorBase
  private
    def atom_name
      @atom_name || name
    end

    def application_class
      Rails.application.config.try(:folio_generators_engine_class) || Rails.application.class
    end

    def classname_prefix
      application_class.name[0].downcase
    end

    def plural_dashed_resource_name
      dashed_resource_name.pluralize
    end

    def dashed_resource_name
      model_resource_name.tr("_", "-").gsub("::", "-")
    end

    def atom_cell_name
      "#{application_namespace_path}/atom/#{atom_name}"
    end

    def molecule_name
      class_name
    end

    def molecule_class_name
      "#{classname_prefix}-molecule-#{dashed_resource_name}"
    end

    def molecule_cell_name
      "#{application_namespace_path}/molecule/#{atom_name}"
    end

    def application_namespace_path
      application_namespace.underscore
    end

    def application_namespace
      application_class.name.deconstantize
    end

    def application_namespace_spacing
      @application_namespace_spacing ||= application_namespace.to_s.gsub(/\w/, " ")
    end

    def add_atom_to_i18n_ymls(values = {})
      I18n.available_locales.each do |locale|
        path = Rails.root.join("config/locales/atom.#{locale}.yml")
        i18n_key = "#{application_namespace_path}/atom/#{atom_name}"
        i18n_value = values[locale] || values[locale.to_s] || values[:en]

        if i18n_value.is_a?(Hash)
          new_hash = { locale.to_s => i18n_value }
        else
          new_hash = {
            locale.to_s => {
              "activerecord" => {
                "models" => {
                  i18n_key => i18n_value || atom_name.capitalize
                }
              }
            }
          }
        end

        if new_hash[locale.to_s]["activerecord"]["attributes"]
          if new_hash[locale.to_s]["activerecord"]["attributes"][i18n_key].blank?
            new_hash[locale.to_s]["activerecord"].delete("attributes")
          end
        end

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

        if hash[locale.to_s]["activerecord"]["attributes"]
          sorted = hash[locale.to_s]["activerecord"]["attributes"].sort_by { |key, _v| key }
          hash[locale.to_s]["activerecord"]["attributes"] = Hash[ sorted ]
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
end
