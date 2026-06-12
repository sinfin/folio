# frozen_string_literal: true

class Folio::ConsolePresence < Folio::ApplicationRecord
  WINDOW = 5.minutes

  belongs_to :user, class_name: "Folio::User"
  belongs_to :record, polymorphic: true

  scope :fresh, -> { where(updated_at: WINDOW.ago..) }

  scope :for_record, ->(record) do
    where(record_type: record.class.base_class.name, record_id: record.id)
  end

  scope :others_editing, ->(record, except_user_id:) do
    for_record(record).fresh.where.not(user_id: except_user_id)
  end
end
