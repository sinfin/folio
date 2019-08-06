# frozen_string_literal: true

class Folio::DownloadsController < ApplicationController
  layout false
  before_action :find_file

  def show
    respond_to do |format|
      format.all do
        redirect_to @file.file.remote_url
      end
    end
  end

  private

    def find_file
      @file = Folio::File.friendly.find(params[:hash_id])
    end
end
