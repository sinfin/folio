# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module InputGroupAppendComponent
      def input_group_append(wrapper_options = nil)
        options[:input_group_append]
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::InputGroupAppendComponent)
