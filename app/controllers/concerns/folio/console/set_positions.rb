# frozen_string_literal: true

module Folio
  module Console
    module SetPositions
      extend ActiveSupport::Concern

      def set_positions
        if self.class.positions_model.update(set_position_params.keys,
                                             set_position_params.values)
          render json: {}
        else
          head 406
        end
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
