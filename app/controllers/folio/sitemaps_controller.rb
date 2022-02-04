# frozen_string_literal: true

class Folio::SitemapsController < ActionController::Base
  def show
    filename = File.basename(request.path)
    data = open("https://#{ENV["S3_BUCKET_NAME"]}.s3.amazonaws.com/sitemaps/#{filename}")

    send_data data.read, filename: filename, type: data.content_type
  rescue OpenURI::HTTPError
    head 404
  end
end
