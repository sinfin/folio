# frozen_string_literal: true

module Folio::HasAasmStates
  extend ActiveSupport::Concern

  included do
    include AASM

    before_validation :set_aasm_state_log

    def self.all_state_names
      aasm.states.to_a.collect(&:name)
    end

    def self.all_event_names
      aasm.events.to_a.collect(&:name)
    end

    def permitted_event_names(*args) # some quards may need parameter
      aasm.events({ permitted: true }, *args).map(&:name)
    end

    def allowed_events_for(user, *args)
      return [] unless user

      aasm.events({ permitted: true }, *args).select do |event|
        !event.options[:private] && user.can_now?(event.name.to_sym, self)
      end
    end

    def current_state_aasm_object
      state_aasm_object_for(aasm_state.to_sym)
    end

    def state_aasm_object_for(state_name)
      aasm.state_object_for_name(state_name.to_sym)
    end
  end

  private
    def set_aasm_state_log
      return unless respond_to?(:aasm_state_log)

      aasm_state_changes = changes["aasm_state"]
      return if aasm_state_changes.blank?

      entry = {
        "from" => (aasm_state_changes.first || :void).to_s,
        "to" => aasm_state_changes.last.to_s,
        "time" => Time.current
      }

      if user = Folio::Current.user
        entry["folio_user_id"] = user.id
      end

      current = aasm_state_log.is_a?(Array) ? aasm_state_log : []
      return if current.last && current.last.except("time") == entry.except("time")

      self.aasm_state_log = current + [entry]
    end
end
