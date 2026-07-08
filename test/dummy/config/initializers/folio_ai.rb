# frozen_string_literal: true

if Rails.env.development?
  Folio::Ai.configure do |config|
    config.default_provider = :dummy
  end

  Rails.application.config.after_initialize do
    Folio::Ai.register_record(record_class_name: "Dummy::Blog::Article",
                              fields: [
                                { key: :title, character_limit: 120 },
                                { key: :perex, character_limit: 400 },
                                { key: :meta_title, character_limit: 120 },
                                { key: :meta_description, character_limit: 400 },
                              ])
  rescue ArgumentError => e
    raise unless e.message.include?("already registered")
  end
end
