# frozen_string_literal: true

class Folio::DownloadsController < ActionController::Base
  layout false
  before_action :find_file

  def show
    redirect_to download_url_for(@file), allow_other_host: true
  end

  private
    def find_file
      @file = Folio::File.friendly.find(params[:hash_id])
    rescue ActiveRecord::RecordNotFound
      @file = Folio::PrivateAttachment.friendly.find(params[:hash_id])
    end

    def download_url_for(file)
      if file.is_a?(Folio::PrivateAttachment) || file.try(:private?)
        # Private files need presigned URLs for S3 access
        Folio::S3.url_rewrite(file.file.remote_url(expires: 1.hour.from_now))
      else
        # Public files can use CDN
        Folio::S3.cdn_url_rewrite(file.file.remote_url)
      end
    end
end
