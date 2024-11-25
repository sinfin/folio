# frozen_string_literal: true

class Folio::SitemapsController < ActionController::Base
  include Folio::SetCurrentRequestDetails

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
      "https://s3.#{ENV["S3_REGION"]}.amazonaws.com/#{ENV["S3_BUCKET_NAME"]}/sitemaps/#{Folio::Current.site.domain}/#{filename}"
    end
end
