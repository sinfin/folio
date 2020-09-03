# frozen_string_literal: true

Audited::Audit.class_eval do
  before_create :set_placement_version_number

  private
    def set_placement_version_number
      if auditable_type == 'Folio::Atom::Base'
        self.placement_version = associated.audits.last.version
      end
    end
end
