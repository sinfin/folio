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
