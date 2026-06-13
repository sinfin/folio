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

# == Schema Information
#
# Table name: folio_console_presences
#
#  id          :bigint(8)        not null, primary key
#  user_id     :bigint(8)        not null
#  record_type :string           not null
#  record_id   :bigint(8)        not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_folio_console_presences_on_record_and_freshness  (record_type,record_id,updated_at)
#  index_folio_console_presences_on_user_and_record       (user_id,record_type,record_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => folio_users.id)
#
