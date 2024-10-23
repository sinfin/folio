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
