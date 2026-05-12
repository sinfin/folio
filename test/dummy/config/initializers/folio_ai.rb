# frozen_string_literal: true

if Rails.env.development?
  Folio::Ai.configure do |config|
    config.enabled = true
  end

  Rails.application.config.after_initialize do
    Folio::Ai.register_integration(record_class_name: "Dummy::Blog::Article",
                                   fields: [
                                     Folio::Ai::Field.new(key: :title,
                                                          input_types: %i[string],
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :perex,
                                                          input_types: %i[text],
                                                          character_limit: 400),
                                     Folio::Ai::Field.new(key: :meta_title,
                                                          input_types: %i[string],
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :meta_description,
                                                          input_types: %i[text],
                                                          character_limit: 400),
                                   ])
  rescue ArgumentError => e
    raise unless e.message.include?("already registered")
  end
end
