# frozen_string_literal: true

class Folio::DownloadsController < ActionController::Base
  layout false
  before_action :find_file

  def show
    redirect_to @file.file.remote_url, allow_other_host: true
  end

  private
    def find_file
      @file = Folio::File.friendly.find(params[:hash_id])
    rescue ActiveRecord::RecordNotFound
      @file = Folio::PrivateAttachment.friendly.find(params[:hash_id])
    end
end
