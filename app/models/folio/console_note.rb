# frozen_string_literal: true

class Folio::ConsoleNote < Folio::ApplicationRecord
  include Folio::Positionable

  has_sanitized_fields :content

  belongs_to :target, polymorphic: true

  belongs_to :created_by, class_name: "Folio::Account",
                          inverse_of: :created_console_notes,
                          required: false

  belongs_to :closed_by, class_name: "Folio::Account",
                         inverse_of: :closed_console_notes,
                         required: false

  validates :content,
            presence: true
end

# == Schema Information
#
# Table name: folio_console_notes
#
#  id            :bigint(8)        not null, primary key
#  content       :text
#  target_type   :string
#  target_id     :bigint(8)
#  created_by_id :bigint(8)
#  closed_by_id  :bigint(8)
#  closed_at     :datetime
#  due_at        :datetime
#  position      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_folio_console_notes_on_closed_by_id   (closed_by_id)
#  index_folio_console_notes_on_created_by_id  (created_by_id)
#  index_folio_console_notes_on_target         (target_type,target_id)
#
