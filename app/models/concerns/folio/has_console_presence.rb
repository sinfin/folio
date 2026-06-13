# frozen_string_literal: true

module Folio::HasConsolePresence
  extend ActiveSupport::Concern

  included do
    has_many :console_presences,
             class_name: "Folio::ConsolePresence",
             dependent: :delete_all
  end

  def touch_console_presence!(record)
    return if record.blank?

    now = Time.current
    attrs = { record_type: record.class.base_class.name, record_id: record.id }

    presence = console_presences.find_or_initialize_by(attrs)
    presence.updated_at = now
    presence.save!

    touch_console_active!(now)
  rescue ActiveRecord::RecordNotUnique
    # another request inserted the row between find_or_initialize_by and save!
    console_presences.where(attrs).update_all(updated_at: now)
    touch_console_active!(now)
  end

  def touch_console_active!(now = Time.current)
    update_columns(console_active_at: now)
  end

  def clear_console_presence!
    console_presences.delete_all
  end
end
