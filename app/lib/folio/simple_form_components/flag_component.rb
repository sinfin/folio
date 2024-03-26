# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module FlagComponent
      CDN = "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/2.9.0/flags"

      def flag(wrapper_options = nil)
        @flag ||= if options[:flag].present?
          Folio::Console::Ui::FlagCell.new(options[:flag]).show.html_safe
        end
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::FlagComponent)
