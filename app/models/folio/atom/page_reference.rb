# frozen_string_literal: true

module Folio
  module Atom
    class PageReference < Base
      ALLOWED_MODEL_TYPE = 'Folio::Page'

      def self.form
        :select
      end
    end
  end
end
