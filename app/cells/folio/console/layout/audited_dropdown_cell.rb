# frozen_string_literal: true

class Folio::Console::Layout::AuditedDropdownCell < Folio::ConsoleCell
  def show
    render if model.present? && model.size > 1
  end

  def item_class_name(i)
    if i == 0
      "f-c-layout-audited-dropdown__item--active"
    else
      "f-c-layout-audited-dropdown__item--link"
    end
  end

  def version_url(version)
    url_for([:revision, :console, version, version: version.audit_version])
  end
end
