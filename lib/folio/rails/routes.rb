# frozen_string_literal: true

require 'action_dispatch'

module ActionDispatch
  module Routing
    class Mapper
      def folio_console_versions_for(klass)
        resources :versions, only: :index, defaults: { item_class: klass.to_s }
      end
    end
  end
end
