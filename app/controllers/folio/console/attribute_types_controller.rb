# frozen_string_literal: true

class Folio::Console::AttributeTypesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::AttributeType"

  def new
    @attribute_type = @klass.new(type: params[:type])
  end

  private
    def attribute_type_params
      params.require(:attribute_type)
            .permit(*(@klass.column_names - %w[id site_id]))
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
