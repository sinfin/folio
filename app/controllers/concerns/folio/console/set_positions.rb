# frozen_string_literal: true

module Folio
  module Console
    module SetPositions
      extend ActiveSupport::Concern

      def set_positions
        model = self.class.positions_model

        model.where(id: set_position_params.keys).each do |record|
          position = set_position_params[record.id.to_s]["position"]
          record.positionable_sql_update(position)
        end

        render json: {}
      end

      module ClassMethods
        attr_reader :positions_model

        private
          def handles_set_positions_for(positions_model)
            @positions_model = positions_model
          end
      end

      private
        def set_position_params
          params.require(:positions)
        end
    end
  end
end
