# frozen_string_literal: true

class Folio::SitemapsController < ActionController::Base
  include Folio::HasCurrentSite

  def show
    filename = File.basename(request.path)
    uri = URI.parse(s3_sitemap_url(filename))
    data = uri.open

    send_data data.read, filename:, type: data.content_type
  rescue OpenURI::HTTPError
    head 404
  end

  private
    def s3_sitemap_url(filename)
      "https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/sitemaps/#{current_site.domain}/#{filename}"
    end
end
