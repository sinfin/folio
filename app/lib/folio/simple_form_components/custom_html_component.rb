# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module CustomHtmlComponent
      def custom_html(wrapper_options = nil)
        options[:custom_html]
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::CustomHtmlComponent)
