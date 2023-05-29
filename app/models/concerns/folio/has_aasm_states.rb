# frozen_string_literal: true

module Folio::HasAasmStates
  extend ActiveSupport::Concern

  included do
    include AASM

    def self.all_state_names
      aasm.states.to_a.collect(&:name)
    end

    def self.all_event_names
      aasm.events.to_a.collect(&:name)
    end

    def permitted_event_names(*args) # some quards may need parameter
      aasm.events({ permitted: true }, *args).map(&:name)
    end
  end
end
