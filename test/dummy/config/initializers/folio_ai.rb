# frozen_string_literal: true

if Rails.env.development?
  Folio::Ai.configure do |config|
    config.enabled = true
    config.default_provider = :demo
    config.provider_models = {
      demo: "demo",
    }
  end

  Rails.application.config.after_initialize do
    Folio::Ai.register_integration(record_class_name: "Dummy::Blog::Article",
                                   fields: [
                                     Folio::Ai::Field.new(key: :title,
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :perex,
                                                          character_limit: 400),
                                     Folio::Ai::Field.new(key: :meta_title,
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :meta_description,
                                                          character_limit: 400),
                                     Folio::Ai::Field.new(key: :all_ai_inputs,
                                                          label: "All AI inputs"),
                                   ])
  rescue ArgumentError => e
    raise unless e.message.include?("already registered")
  end
end
