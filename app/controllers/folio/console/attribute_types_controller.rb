# frozen_string_literal: true

class Folio::Console::AttributeTypesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::AttributeType"

  def new
    @attribute_type = @klass.new(type: params[:type])
  end

  private
    def additional_attribute_type_params
      # to be overriden in main_app should it be needed
      []
    end

    def attribute_type_params
      params.require(:attribute_type)
            .permit(*folio_using_traco_aware_param_names(:title),
                    :type,
                    :position,
                    :data_type,
                    *additional_attribute_type_params)
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
