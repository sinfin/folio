# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::Tiptap::NodeGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def node_model
    template "node_model.rb.tt", "app/models/#{application_namespace_path}/tiptap/node/#{name}.rb"
  end

  def component
    unless File.exist?(Rails.root.join("app/components/#{application_namespace_path}/tiptap/node/base_component.rb"))
      template "base_component.rb.tt", "app/components/#{application_namespace_path}/tiptap/node/base_component.rb"
    end

    template "component.rb.tt", "app/components/#{application_namespace_path}/tiptap/node/#{name}_component.rb"
    template "component.slim.tt", "app/components/#{application_namespace_path}/tiptap/node/#{name}_component.slim"
    template "component_test.rb.tt", "test/components/#{application_namespace_path}/tiptap/node/#{name}_component_test.rb"
  end

  def node_css_class_name
    "#{classname_prefix}-tiptap-node-#{dashed_resource_name}"
  end

  def i18n_yml
    add_tiptap_node_to_i18n_ymls
  end

  def base_component_name
    "#{application_namespace}::Tiptap::Node::BaseComponent"
  end

  def node_model_name
    "#{application_namespace}::Tiptap::Node::#{class_name}"
  end

  def node_component_name
    "#{node_model_name}Component"
  end

  private
    def add_tiptap_node_to_i18n_ymls
      I18n.available_locales.each do |locale|
        locale_s = locale.to_s
        file_path = Rails.root.join("config/locales/tiptap/nodes.#{locale_s}.yml")

        if File.exist?(file_path)
          yaml_hash = YAML.load_file(file_path)
        else
          yaml_hash = {
            locale_s => {
              "activemodel" => {
                "attributes" => {},
                "models" => {}
              }
            }
          }

          FileUtils.mkdir_p(File.dirname(file_path))
          File.write(file_path, yaml_hash.to_yaml(line_width: -1))
        end

        i18n_key = "#{application_namespace_path}/tiptap/node/#{name}"

        yaml_hash[locale_s]["activemodel"]["attributes"][i18n_key] ||= nil
        yaml_hash[locale_s]["activemodel"]["models"][i18n_key] ||= name.split("/").pop.capitalize

        # recursively sort keys
        sort_hash = lambda do |hash|
          sorted = hash.map do |key, value|
            [key, value.is_a?(Hash) ? sort_hash.call(value) : value]
          end.sort_by { |key, _value| key }

          Hash[sorted]
        end

        sorted_yaml_hash = sort_hash.call(yaml_hash)

        File.write(file_path, sorted_yaml_hash.to_yaml(line_width: -1))
      end
    end
end
