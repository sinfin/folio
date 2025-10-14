# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module ControlsComponent
      def controls(wrapper_options = nil)
        @controls = []

        if options[:clear_button].present?
          @controls << options[:clear_button]
        end

        safe_join(@controls)
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::ControlsComponent)
