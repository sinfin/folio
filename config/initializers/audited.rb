# frozen_string_literal: true

# when in impersonation, still use real user
Audited.current_user_method = :true_user
Audited.auditing_enabled = !(Rails.env.test?)
