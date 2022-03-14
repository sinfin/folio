# frozen_string_literal: true

module Folio::HasConsoleNotes
  extend ActiveSupport::Concern

  included do
    has_many :console_notes, -> { ordered },
                             class_name: "Folio::Console::Note",
                             as: :target,
                             inverse_of: :target,
                             dependent: :destroy

    accepts_nested_attributes_for :console_notes,
                                  reject_if: :all_blank,
                                  allow_destroy: true
  end
end
