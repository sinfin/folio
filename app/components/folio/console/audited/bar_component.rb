# frozen_string_literal: true

class Folio::Console::Audited::BarComponent < Folio::Console::ApplicationComponent
  def initialize(audited_revision:)
    @audited_revision = audited_revision
  end

  def render?
    @audited_revision.present?
  end

  def restore_link
    return unless @audited_revision.class.audited_console_restorable?

    href = url_for([:restore, :console, @audited_revision, version: @audited_revision.audit_version])

    folio_console_ui_button(label: t(".restore"),
                            href:,
                            method: :post,
                            data: { confirm: t("folio.console.confirmation") })
  end

  def show_url
    url_for([:console, @audited_revision, action: @audited_revision.class.audited_console_view_name])
  end
end
