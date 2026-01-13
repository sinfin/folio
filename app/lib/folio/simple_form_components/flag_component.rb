# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module FlagComponent
      def flag(wrapper_options = nil)
        @flag ||= if options[:flag].present?
          @builder.template.render(Folio::Console::Ui::FlagComponent.new(locale: options[:flag])).html_safe
        end
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::FlagComponent)
