# frozen_string_literal: true

module Folio::Console::AuditsHelper
  def console_audits_table(audited)
    revisions = audited.revisions.reverse

    render "audits", audited: audited, revisions: revisions
  end
end
