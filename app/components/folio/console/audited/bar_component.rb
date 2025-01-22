# frozen_string_literal: true

class Folio::Console::Audited::BarComponent < Folio::Console::ApplicationComponent
  def initialize(audit:, record:)
    @audit = audit
    @record = record
  end

  def render?
    @audit.present? && @record.present?
  end

  def restore_link
    return unless @record.class.audited_console_restorable?

    href = url_for([:restore, :console, @record, version: @audit.version])

    folio_console_ui_button(label: t(".restore"),
                            href:,
                            method: :post,
                            data: { confirm: t("folio.console.confirmation") })
  end

  def show_url
    url_for([:console, @record, action: :edit])
  end
end
