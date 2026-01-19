# frozen_string_literal: true

FactoryBot.define do
  factory :folio_cache_version, class: "Folio::Cache::Version" do
    sequence(:key) { |i| "cache-key-#{i}" }
    site { get_current_or_existing_site_or_create_from_factory }
  end
end
