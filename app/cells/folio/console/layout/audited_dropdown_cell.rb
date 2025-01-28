# frozen_string_literal: true

class Folio::Console::Layout::AuditedDropdownCell < Folio::ConsoleCell
  def show
    render if model.present? && model.size > 1 && options[:record].present? && options[:record].should_audit_changes?
  end

  def item_class_name(version, i)
    if options[:audited_audit]
      active = version.id == options[:audited_audit].id
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
      url_for([:edit, :console, options[:record]])
    else
      url_for([:revision, :console, options[:record], version: version.version])
    end
  end
end
