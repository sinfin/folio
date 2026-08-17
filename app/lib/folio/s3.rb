# frozen_string_literal: true

module Folio::S3
  def self.dragonfly_url_for(uid, expires: nil)
    opts = {}
    opts[:expires] = expires if expires && !file_datastore?

    url_rewrite(Dragonfly.app.datastore.url_for(uid, opts))
  end

  def self.file_datastore?
    Dragonfly.app.datastore.is_a?(Dragonfly::FileDataStore)
  end

  def self.s3_datastore?
    Dragonfly.app.datastore.is_a?(Dragonfly::S3DataStore)
  end

  def self.url_rewrite(url)
    if url && ENV["S3_BUCKET_NAME"].present?
      url.gsub("https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/",
               "https://s3.#{ENV["S3_REGION"]}.amazonaws.com/#{ENV["S3_BUCKET_NAME"]}/")
    else
      url
    end
  end

  def self.cdn_url_rewrite(url)
    if url && ENV["S3_CDN_HOST"].present?
      Folio::S3.url_rewrite(url)
               .gsub("https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/", "https://#{ENV["S3_CDN_HOST"]}/")
               .gsub("https://s3.#{ENV["S3_REGION"]}.amazonaws.com/#{ENV["S3_BUCKET_NAME"]}/", "https://#{ENV["S3_CDN_HOST"]}/")
    else
      Folio::S3.url_rewrite(url)
    end
  end
end
