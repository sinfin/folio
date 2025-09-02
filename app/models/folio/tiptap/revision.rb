# frozen_string_literal: true

class Folio::Tiptap::Revision < Folio::ApplicationRecord
  self.table_name = "folio_tiptap_revisions"

  MAX_REVISIONS = 20

  belongs_to :placement, polymorphic: true
  belongs_to :user, class_name: "Folio::User", optional: true

  validates :revision_number, presence: true
  # Note: content validation intentionally minimal for auto-save
  validates :revision_number, uniqueness: {
    scope: [:placement_type, :placement_id]
  }

  scope :ordered, -> { order(revision_number: :desc) }
  scope :latest_first, -> { order(created_at: :desc) }

  before_validation :set_revision_number, on: :create
  after_create :cleanup_old_revisions, if: :should_cleanup?

  def to_label
    "Revision ##{revision_number} (#{created_at.strftime('%d.%m.%Y %H:%M')})"
  end

  private
    def set_revision_number
      return if revision_number.present?

      last_revision = self.class.where(
        placement_type: placement_type,
        placement_id: placement_id
      ).maximum(:revision_number) || 0

      self.revision_number = last_revision + 1
    end

    def should_cleanup?
      revision_number % 10 == 0
    end

    def cleanup_old_revisions
      # Find revisions to delete (keep only the newest MAX_REVISIONS)
      revisions_to_delete = self.class
        .where(placement_type:, placement_id:)
        .order(created_at: :desc)
        .offset(MAX_REVISIONS)

      if revisions_to_delete.exists?
        deleted_count = revisions_to_delete.delete_all
        Rails.logger.info "Cleaned up #{deleted_count} old tiptap revisions for #{placement_type}##{placement_id}"
      end
    end
end
