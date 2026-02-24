# frozen_string_literal: true

class Folio::Tiptap::Revision < Folio::ApplicationRecord
  self.table_name = "folio_tiptap_revisions"

  belongs_to :placement, polymorphic: true
  belongs_to :user, class_name: "Folio::User", optional: true
  belongs_to :superseded_by_user, class_name: "Folio::User", optional: true

  # content validation is intentionally minimal for auto-save
  validates :user_id, uniqueness: { scope: [:placement_type, :placement_id, :attribute_name] }

  def superseded?
    superseded_by_user_id.present?
  end
end

# == Schema Information
#
# Table name: folio_tiptap_revisions
#
#  id                    :bigint(8)        not null, primary key
#  placement_type        :string           not null
#  placement_id          :bigint(8)        not null
#  user_id               :bigint(8)
#  superseded_by_user_id :bigint(8)
#  content               :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  attribute_name        :string           default("tiptap_content"), not null
#
# Indexes
#
#  index_folio_tiptap_revisions_on_placement              (placement_type,placement_id)
#  index_folio_tiptap_revisions_on_superseded_by_user_id  (superseded_by_user_id)
#  index_folio_tiptap_revisions_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (superseded_by_user_id => folio_users.id)
#  fk_rails_...  (user_id => folio_users.id)
#
