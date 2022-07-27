# frozen_string_literal: true

class Folio::CellGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def cell
    handle_folio_cell_generator_class_name_prefixes

    template "cell.rb.tt", "app/cells/#{cell_name}_cell.rb"
    template "cell.slim.tt", "app/cells/#{cell_name}/show.slim"
    template "cell_test.rb.tt", "test/cells/#{cell_name}_cell_test.rb"
  end

  private
    def handle_folio_cell_generator_class_name_prefixes
      if Rails.application.config.folio_cell_generator_class_name_prefixes
        to_check = "#{application_namespace}#{class_name}"

        key = Rails.application.config.folio_cell_generator_class_name_prefixes.keys.find do |prefix, cn_prefix|
          to_check.start_with?(prefix)
        end

        if key
          @classname_prefix = "#{Rails.application.config.folio_cell_generator_class_name_prefixes[key]}-"
          @force_classname_prefix = @classname_prefix
          to_be_replaced = "#{key.gsub(/\A#{application_namespace}/, "").underscore.tr('/', '_')}"
          @dashed_resource_name = model_resource_name.gsub(/\A#{to_be_replaced}_/, "")
        else
          @classname_prefix = "#{Rails.application.class.name[0].downcase}-"
          @dashed_resource_name = model_resource_name
        end

        @dashed_resource_name = @dashed_resource_name.tr("_", "-")
      end
    end

    def classname_prefix
      if @force_classname_prefix
        @force_classname_prefix
      elsif name.start_with?("/")
        ""
      else
        @classname_prefix
      end
    end

    def model_resource_name
      super.delete_prefix("_")
    end

    def class_name
      super.delete_prefix("::")
    end

    attr_reader :dashed_resource_name

    def cell_name
      "#{application_namespace_path}#{name.delete_prefix('/')}"
    end

    def application_namespace_path
      application_namespace.underscore
    end

    def application_namespace
      if name.start_with?("/")
        ""
      else
        "#{Rails.application.class.name.deconstantize}::"
      end
    end
end
