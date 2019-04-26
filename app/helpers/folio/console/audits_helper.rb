# frozen_string_literal: true

module Folio::Console::AuditsHelper
  def console_audits_table(audited)
    audits = audited.revisions.reverse

    render 'audits', audited: audited, audits: audits
  end
end
