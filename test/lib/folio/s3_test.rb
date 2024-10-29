# frozen_string_literal: true

require "test_helper"

class Folio::S3Test < ActiveSupport::TestCase
  test "url_rewrite" do
    old_base = "https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/"
    new_base = "https://s3.#{ENV["S3_REGION"]}.amazonaws.com/#{ENV["S3_BUCKET_NAME"]}/"

    {
      "#{old_base}" => "#{new_base}",
      "#{old_base}foo/bar/baz.txt" => "#{new_base}foo/bar/baz.txt",
      "https://foo.com/bar/baz.txt" => "https://foo.com/bar/baz.txt",
      "/image.jpg" => "/image.jpg",
    }.each do |from, to|
      assert_equal to, Folio::S3.url_rewrite(from), "#{from} => #{to}"
    end
  end

  test "cdn_url_rewrite" do
    old_env = ENV.to_hash

    begin
      ENV.update("S3_CDN_HOST" => "cdn-host")

      old_base = "https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/"
      new_base = "https://s3.#{ENV["S3_REGION"]}.amazonaws.com/#{ENV["S3_BUCKET_NAME"]}/"
      cdn_base = "https://cdn-host/"

      {
        "#{old_base}" => "#{cdn_base}",
        "#{old_base}foo/bar/baz.txt" => "#{cdn_base}foo/bar/baz.txt",
        "#{new_base}" => "#{cdn_base}",
        "#{new_base}foo/bar/baz.txt" => "#{cdn_base}foo/bar/baz.txt",
        "https://foo.com/bar/baz.txt" => "https://foo.com/bar/baz.txt",
        "/image.jpg" => "/image.jpg",
      }.each do |from, to|
        assert_equal to, Folio::S3.cdn_url_rewrite(from), "#{from} => #{to}"
      end
    ensure
      ENV.replace(old_env)
    end

    begin
      ENV.update("S3_CDN_HOST" => nil)

      old_base = "https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/"
      new_base = "https://s3.#{ENV["S3_REGION"]}.amazonaws.com/#{ENV["S3_BUCKET_NAME"]}/"

      {
        "#{old_base}" => "#{new_base}",
        "#{old_base}foo/bar/baz.txt" => "#{new_base}foo/bar/baz.txt",
        "#{new_base}" => "#{new_base}",
        "#{new_base}foo/bar/baz.txt" => "#{new_base}foo/bar/baz.txt",
        "https://foo.com/bar/baz.txt" => "https://foo.com/bar/baz.txt",
        "/image.jpg" => "/image.jpg",
      }.each do |from, to|
        assert_equal to, Folio::S3.cdn_url_rewrite(from), "#{from} => #{to}"
      end
    ensure
      ENV.replace(old_env)
    end
  end
end
