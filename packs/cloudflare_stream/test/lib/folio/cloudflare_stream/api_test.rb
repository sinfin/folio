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

  test "applies configured HTTP timeouts" do
    fake_http = TimeoutRecordingHttp.new({
      "success" => true,
      "result" => {
        "uid" => "video-1",
        "readyToStream" => false,
      },
    })

    original_open_timeout = Rails.application.config.folio_cloudflare_stream_api_open_timeout
    original_read_timeout = Rails.application.config.folio_cloudflare_stream_api_read_timeout
    original_write_timeout = Rails.application.config.folio_cloudflare_stream_api_write_timeout
    Rails.application.config.folio_cloudflare_stream_api_open_timeout = 3
    Rails.application.config.folio_cloudflare_stream_api_read_timeout = 11
    Rails.application.config.folio_cloudflare_stream_api_write_timeout = 13

    Net::HTTP.stub(:new, fake_http) do
      api = Folio::CloudflareStream::Api.new(account_id: "account-1", api_token: "token-1")
      result = api.copy(url: "https://s3.example.com/source.mp4")

      assert_equal "video-1", result["uid"]
    end

    assert_equal true, fake_http.use_ssl
    assert_equal 3, fake_http.open_timeout
    assert_equal 11, fake_http.read_timeout
    assert_equal 13, fake_http.write_timeout
  ensure
    Rails.application.config.folio_cloudflare_stream_api_open_timeout = original_open_timeout
    Rails.application.config.folio_cloudflare_stream_api_read_timeout = original_read_timeout
    Rails.application.config.folio_cloudflare_stream_api_write_timeout = original_write_timeout
  end

  test "error exposes HTTP status helpers" do
    not_found_error = Folio::CloudflareStream::Api::Error.new("not found", status_code: 404)
    unavailable_error = Folio::CloudflareStream::Api::Error.new("unavailable", status_code: 503)

    assert not_found_error.not_found?
    assert_not unavailable_error.not_found?
    assert unavailable_error.retryable?
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
    assert_equal 400, error.status_code
  end

  class TimeoutRecordingHttp
    attr_accessor :use_ssl, :open_timeout, :read_timeout, :write_timeout

    def initialize(body)
      @body = body
    end

    def request(_request)
      Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
        response.instance_variable_set(:@read, true)
        response.body = @body.to_json
      end
    end
  end
end
