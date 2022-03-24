# frozen_string_literal: true

class Folio::SitemapsController < ActionController::Base
  def show
    filename = File.basename(request.path)
    data = open(s3_sitemap_url(filename))

    send_data data.read, filename:, type: data.content_type
  rescue OpenURI::HTTPError
    head 404
  end

  private
    def s3_sitemap_url(filename)
      "https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/sitemaps/#{filename}"
    end
end
