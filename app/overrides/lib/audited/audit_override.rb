# frozen_string_literal: true

Audited::Audit.class_eval do
  before_create :set_placement_version_number

  private
    def set_placement_version_number
      if auditable_type.in?(%w[Folio::Atom::Base Folio::FilePlacement::Base])
        self.placement_version = associated.audits.last.try(:version) || 1
      end
    end
end
