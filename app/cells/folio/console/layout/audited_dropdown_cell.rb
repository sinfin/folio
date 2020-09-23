# frozen_string_literal: true

class Folio::Console::Layout::AuditedDropdownCell < Folio::ConsoleCell
  def show
    render if model.present? && model.size > 1
  end

  def item_class_name(version, i)
    if options[:audited_revision]
      active = version.audit.id == options[:audited_revision].audit.id
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
      if version.class.audited_view_name == :show
        url_for([:console, version])
      else
        url_for([version.class.audited_view_name, :console, version])
      end
    else
      url_for([:revision, :console, version, version: version.audit_version])
    end
  end
end
