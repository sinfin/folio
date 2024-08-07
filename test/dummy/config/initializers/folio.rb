# frozen_string_literal: true

Rails.application.config.folio_users_confirmable = false
Rails.application.config.folio_pages_audited = true
Rails.application.config.folio_pages_ancestry = !Rails.env.test?

Rails.application.config.folio_shared_files_between_sites = true
