# frozen_string_literal: true

class Folio::Audited::Audit < Audited::Audit
  before_validation :store_folio_data

  private
    def store_folio_data
      auditor = Folio::Audited::Auditor.new(record: auditable)
      self.folio_data = auditor.get_folio_audited_data
    end
end
