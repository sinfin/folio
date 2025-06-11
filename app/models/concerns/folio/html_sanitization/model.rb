# frozen_string_literal: true

module Folio
  module HtmlSanitization
    module Model
      extend ActiveSupport::Concern

      included do
        before_validation :folio_html_sanitize
      end

      # This method can be overridden in the model to provide custom sanitization configuration.
      def folio_html_sanitization_config
        {
          enabled: true,
          attributes: {},
        }
      end

      private
        def folio_html_sanitize
          Folio::HtmlSanitization::Sanitizer.sanitize(record: self)
        end
    end
  end
end
