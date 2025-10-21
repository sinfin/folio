# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module InputControlsComponent
      def input_controls(wrapper_options = nil)
        options[:input_controls]
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::InputControlsComponent)
