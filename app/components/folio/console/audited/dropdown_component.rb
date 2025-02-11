# frozen_string_literal: true

class Folio::Console::Audited::DropdownComponent < Folio::Console::ApplicationComponent
  def initialize(audits:, audit: nil, record:)
    @audits = audits
    @audit = audit
    @record = record
  end

  def render?
    @audits.present? && @audits.size > 1 && @record && @record.should_audit_changes?
  end

  def item_class_name(version, i)
    if @audit
      active = @audit.present? && version.id == @audit.id
    else
      active = i == 0
    end

    if active
      "f-c-layout-audited-dropdown__item--active"
    else
      "f-c-layout-audited-dropdown__item--link"
    end
  end

  def version_url(version, i)
    if i == 0
      url_for([:edit, :console, @record])
    else
      url_for([:revision, :console, @record, version: version.version])
    end
  end
end
