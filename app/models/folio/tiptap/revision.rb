# frozen_string_literal: true

class Folio::Tiptap::Revision < Folio::ApplicationRecord
  self.table_name = "folio_tiptap_revisions"

  belongs_to :placement, polymorphic: true
  belongs_to :user, class_name: "Folio::User", optional: true
  belongs_to :superseded_by_user, class_name: "Folio::User", optional: true

  scope :ordered, -> { order(updated_at: :asc) }
  # content validation is intentionally minimal for auto-save
  validates :user_id, uniqueness: { scope: [:placement_type, :placement_id, :attribute_name] }

  def superseded?
    superseded_by_user_id.present?
  end

  def conflicting_with?(other_revision)
    return false if other_revision.nil?
    return false if other_revision.user == user
    return false if other_revision.attribute_name != attribute_name
    return false if superseded? || other_revision.superseded?

    content != other_revision.content
  end

  def stale?
    updated_at < placement.updated_at
  end
end
