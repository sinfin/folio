# frozen_string_literal: true

Rails.application.config.folio_pages_audited = true
Rails.application.config.folio_show_transportable_frontend = true
Rails.application.config.folio_pages_ancestry = !Rails.env.test?
