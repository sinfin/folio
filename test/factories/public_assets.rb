# frozen_string_literal: true

FactoryBot.define do
  factory :folio_public_asset, class: "Folio::PublicAsset" do
    site { association(Rails.application.config.folio_site_default_test_factory || :folio_site) }
    file { Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/files/public_asset.json"), "application/json") }
  end
end
