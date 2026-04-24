# frozen_string_literal: true

if Rails.env.development?
  Rails.application.config.folio_ai_enabled = true

  Rails.application.config.after_initialize do
    Folio::Ai.register_integration(:dummy_blog_articles,
                                   label: "Dummy blog articles",
                                   fields: [
                                     Folio::Ai::Field.new(key: :title,
                                                          label: "Title",
                                                          auto_attach: true,
                                                          input_types: %i[string],
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :perex,
                                                          label: "Perex",
                                                          auto_attach: true,
                                                          input_types: %i[text],
                                                          character_limit: 400),
                                     Folio::Ai::Field.new(key: :meta_title,
                                                          label: "Meta title",
                                                          auto_attach: true,
                                                          input_types: %i[string],
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :meta_description,
                                                          label: "Meta description",
                                                          auto_attach: true,
                                                          input_types: %i[text],
                                                          character_limit: 400),
                                   ])
  rescue ArgumentError => e
    raise unless e.message.include?("already registered")
  end
end
