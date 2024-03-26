# frozen_string_literal: true

class Folio::Console::Layout::AuditedBarCell < Folio::ConsoleCell
  def show
    render if model.present?
  end

  def restore_link
    return unless model.class.audited_restorable?
    link_to(t(".restore"),
            url_for([:restore, :console, model, version: model.audit_version]),
            method: :post,
            "data-confirm" => t("folio.console.confirmation"),
            class: "btn btn-secondary font-weight-bold me-g my-1")
  end

  def show_url
    url_for([:console, model, action: model.class.audited_view_name])
  end
end
