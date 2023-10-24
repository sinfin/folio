# frozen_string_literal: true

Rails.application.config.folio_users_confirmable = false
Rails.application.config.folio_pages_audited = true
Rails.application.config.folio_show_transportable_frontend = true
Rails.application.config.folio_pages_ancestry = !Rails.env.test?
Rails.application.config.folio_console_sidebar_runner_up_link_class_names = [{ links: %w[
  Dummy::Blog::Article
  Dummy::Blog::Topic
] }]

Rails.application.config.folio_ai_assistant_openai_model = "gpt-3.5-turbo-16k"
