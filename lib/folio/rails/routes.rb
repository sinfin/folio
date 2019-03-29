# frozen_string_literal: true

require 'action_dispatch'

module ActionDispatch
  module Routing
    class Mapper
      def folio_console_audits_for(klass)
        resources :audits, only: :index, defaults: { audited_class: klass.to_s }
      end
    end
  end
end
