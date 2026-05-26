# frozen_string_literal: true

require "test_helper"

class Folio::CloudflareStream::ApiTest < ActiveSupport::TestCase
  test "copy posts source URL with bearer token" do
    stub = stub_request(:post, "https://api.cloudflare.com/client/v4/accounts/account-1/stream/copy")
           .with(
             headers: {
               "Authorization" => "Bearer token-1",
             "Content-Type" => "application/json",
             },
             body: {
               input: "https://s3.example.com/source.mp4?X-Amz-Expires=3600",
               meta: { name: "FUL-49 clip" },
             }.to_json,
           )
           .to_return(
             status: 200,
             body: {
               success: true,
               result: {
                 uid: "video-1",
                 readyToStream: false,
                 status: { state: "downloading" },
               },
             }.to_json,
             headers: { "Content-Type" => "application/json" },
           )

    api = Folio::CloudflareStream::Api.new(account_id: "account-1", api_token: "token-1")
    result = api.copy(url: "https://s3.example.com/source.mp4?X-Amz-Expires=3600",
                      meta: { name: "FUL-49 clip" })

    assert_requested stub
    assert_equal "video-1", result["uid"]
    assert_equal false, result["readyToStream"]
  end

  test "copy posts playback restrictions when provided" do
    stub = stub_request(:post, "https://api.cloudflare.com/client/v4/accounts/account-1/stream/copy")
           .with(
             headers: {
               "Authorization" => "Bearer token-1",
               "Content-Type" => "application/json",
             },
             body: {
               input: "https://s3.example.com/source.mp4?X-Amz-Expires=3600",
               meta: { name: "Restricted clip" },
               allowedOrigins: ["fullmoonzine.cz", "www.fullmoonzine.cz"],
               requireSignedURLs: true,
             }.to_json,
           )
           .to_return(
             status: 200,
             body: {
               success: true,
               result: {
                 uid: "video-1",
                 readyToStream: false,
                 status: { state: "downloading" },
               },
             }.to_json,
             headers: { "Content-Type" => "application/json" },
           )

    api = Folio::CloudflareStream::Api.new(account_id: "account-1", api_token: "token-1")
    result = api.copy(url: "https://s3.example.com/source.mp4?X-Amz-Expires=3600",
                      meta: { name: "Restricted clip" },
                      allowed_origins: ["fullmoonzine.cz", "www.fullmoonzine.cz"],
                      require_signed_urls: true)

    assert_requested stub
    assert_equal "video-1", result["uid"]
  end

  test "signed_url_token posts token restrictions and returns token" do
    expires_at = Time.zone.parse("2026-05-26 12:00:00")
    stub = stub_request(:post, "https://api.cloudflare.com/client/v4/accounts/account-1/stream/video-1/token")
           .with(
             headers: {
               "Authorization" => "Bearer token-1",
               "Content-Type" => "application/json",
             },
             body: {
               exp: expires_at.to_i,
             }.to_json,
           )
           .to_return(
             status: 200,
             body: {
               success: true,
               result: {
                 token: "signed-token-1",
               },
             }.to_json,
             headers: { "Content-Type" => "application/json" },
           )

    api = Folio::CloudflareStream::Api.new(account_id: "account-1", api_token: "token-1")
    token = api.signed_url_token("video-1", expires_at:)

    assert_requested stub
    assert_equal "signed-token-1", token
  end

  test "raises readable error on failed response" do
    stub_request(:get, "https://api.cloudflare.com/client/v4/accounts/account-1/stream/video-1")
      .to_return(
        status: 400,
        body: {
          success: false,
          errors: [{ message: "bad request" }],
        }.to_json,
        headers: { "Content-Type" => "application/json" },
      )

    api = Folio::CloudflareStream::Api.new(account_id: "account-1", api_token: "token-1")

    error = assert_raises(Folio::CloudflareStream::Api::Error) do
      api.video("video-1")
    end

    assert_includes error.message, "bad request"
  end
end
