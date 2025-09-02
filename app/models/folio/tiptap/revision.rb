# frozen_string_literal: true

class Folio::Tiptap::Revision < Folio::ApplicationRecord
  self.table_name = "folio_tiptap_revisions"

  belongs_to :placement, polymorphic: true
  belongs_to :user, class_name: "Folio::User", optional: true

  # content validation is intentionally minimal for auto-save
  validates :user_id, uniqueness: {
    scope: [:placement_type, :placement_id],
    message: "can only have one revision per placement"
  }
end
