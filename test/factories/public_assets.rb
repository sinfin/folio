# frozen_string_literal: true

FactoryBot.define do
  factory :folio_file_public_asset, class: "Folio::File::PublicAsset" do
    site { get_current_or_existing_site_or_create_from_factory }
    file { Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/files/public_asset.json"), "application/json") }
  end
end
