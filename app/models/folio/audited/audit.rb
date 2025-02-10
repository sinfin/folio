# frozen_string_literal: true

class Folio::Audited::Audit < Audited::Audit
  before_validation :store_folio_data

  after_save_commit :set_folio_data_ids

  private
    def store_folio_data
      auditor = Folio::Audited::Auditor.new(record: auditable)
      self.folio_data = auditor.get_folio_audited_data
    end

    def set_folio_data_ids
      auditor = Folio::Audited::Auditor.new(record: auditable, audit: self)
      result = auditor.fill_ids_to_folio_data(folio_data:)

      if result[:changed]
        update_column(:folio_data, result[:folio_data])
      end
    end
end

# == Schema Information
#
# Table name: audits
#
#  id                :bigint(8)        not null, primary key
#  auditable_id      :bigint(8)
#  auditable_type    :string
#  associated_id     :bigint(8)
#  associated_type   :string
#  user_id           :bigint(8)
#  user_type         :string
#  username          :string
#  action            :string
#  audited_changes   :jsonb
#  version           :integer          default(0)
#  comment           :string
#  remote_address    :string
#  request_uuid      :string
#  created_at        :datetime
#  placement_version :integer
#  folio_data        :jsonb
#
# Indexes
#
#  associated_index                   (associated_type,associated_id)
#  auditable_index                    (auditable_type,auditable_id,version)
#  index_audits_on_created_at         (created_at)
#  index_audits_on_placement_version  (placement_version)
#  index_audits_on_request_uuid       (request_uuid)
#  user_index                         (user_id,user_type)
#
