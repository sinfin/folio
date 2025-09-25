# frozen_string_literal: true

require "test_helper"

class Folio::EmbedTest < ActiveSupport::TestCase
  test "url_type returns correct type for facebook URLs" do
    assert_equal "facebook", Folio::Embed.url_type("https://www.facebook.com/testpage")
    assert_equal "facebook", Folio::Embed.url_type("https://www.facebook.com/test-page")
    assert_equal "facebook", Folio::Embed.url_type("https://www.facebook.com/test_page")
    assert_equal "facebook", Folio::Embed.url_type("https://www.facebook.com/testpage/")
  end

  test "url_type returns correct type for instagram URLs" do
    assert_equal "instagram", Folio::Embed.url_type("https://www.instagram.com/p/testpost")
    assert_equal "instagram", Folio::Embed.url_type("https://www.instagram.com/p/test-post")
    assert_equal "instagram", Folio::Embed.url_type("https://www.instagram.com/p/test_post")
    assert_equal "instagram", Folio::Embed.url_type("https://www.instagram.com/p/testpost/")
  end

  test "url_type returns correct type for linkedin URLs" do
    assert_equal "linkedin", Folio::Embed.url_type("https://www.linkedin.com/in/testprofile")
    assert_equal "linkedin", Folio::Embed.url_type("https://www.linkedin.com/in/test-profile")
    assert_equal "linkedin", Folio::Embed.url_type("https://www.linkedin.com/in/test_profile")
    assert_equal "linkedin", Folio::Embed.url_type("https://www.linkedin.com/in/testprofile/")
  end

  test "url_type returns correct type for pinterest URLs" do
    assert_equal "pinterest", Folio::Embed.url_type("https://www.pinterest.com/pin/testpin")
    assert_equal "pinterest", Folio::Embed.url_type("https://www.pinterest.com/pin/test-pin")
    assert_equal "pinterest", Folio::Embed.url_type("https://www.pinterest.com/pin/test_pin")
    assert_equal "pinterest", Folio::Embed.url_type("https://www.pinterest.com/pin/testpin/")
  end

  test "url_type returns correct type for tiktok URLs" do
    assert_equal "tiktok", Folio::Embed.url_type("https://www.tiktok.com/@testuser")
    assert_equal "tiktok", Folio::Embed.url_type("https://www.tiktok.com/@test-user")
    assert_equal "tiktok", Folio::Embed.url_type("https://www.tiktok.com/@test_user")
    assert_equal "tiktok", Folio::Embed.url_type("https://www.tiktok.com/@testuser/")
  end

  test "url_type returns correct type for twitter URLs" do
    assert_equal "twitter", Folio::Embed.url_type("https://twitter.com/testuser")
    assert_equal "twitter", Folio::Embed.url_type("https://twitter.com/test-user")
    assert_equal "twitter", Folio::Embed.url_type("https://twitter.com/test_user")
    assert_equal "twitter", Folio::Embed.url_type("https://twitter.com/testuser/")
  end

  test "url_type returns correct type for youtube URLs" do
    assert_equal "youtube", Folio::Embed.url_type("https://www.youtube.com/watch?v=testvideo")
    assert_equal "youtube", Folio::Embed.url_type("https://www.youtube.com/watch?v=test-video")
    assert_equal "youtube", Folio::Embed.url_type("https://www.youtube.com/watch?v=test_video")
    assert_equal "youtube", Folio::Embed.url_type("https://www.youtube.com/watch?v=testvideo/")
  end

  test "url_type returns nil for invalid URLs" do
    assert_nil Folio::Embed.url_type("https://www.example.com")
    assert_nil Folio::Embed.url_type("https://www.facebook.com")
    assert_nil Folio::Embed.url_type("https://www.instagram.com")
    assert_nil Folio::Embed.url_type("invalid-url")
    assert_nil Folio::Embed.url_type("")
    assert_nil Folio::Embed.url_type(nil)
  end

  test "url_type returns nil for malformed social media URLs" do
    assert_nil Folio::Embed.url_type("https://facebook.com/testpage")
    assert_nil Folio::Embed.url_type("https://www.instagram.com/testuser")
    assert_nil Folio::Embed.url_type("https://www.linkedin.com/testprofile")
    assert_nil Folio::Embed.url_type("https://www.youtube.com/testvideo")
  end

  test "url_type handles edge cases" do
    assert_nil Folio::Embed.url_type("https://www.facebook.com/")
    assert_nil Folio::Embed.url_type("https://www.instagram.com/p/")
    assert_nil Folio::Embed.url_type("https://www.linkedin.com/in/")
  end
end
