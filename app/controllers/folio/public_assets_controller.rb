# frozen_string_literal: true

class Folio::PublicAssetsController < ActionController::Base
  # Public original files (including JavaScript) are intentionally embeddable.
  skip_forgery_protection only: :show

  before_action :require_public_assets_enabled

  def show
    asset = Folio::PublicAsset.find_by!(token: params[:token])
    response.headers["Cache-Control"] = "public, max-age=0, must-revalidate"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Access-Control-Allow-Origin"] = "*"
    # Sandboxing native media previews gives their follow-up requests an opaque origin.
    unless asset.file_mime_type.to_s.start_with?("audio/", "video/")
      response.headers["Content-Security-Policy"] = "sandbox allow-scripts"
    end
    return unless stale?(etag: [asset.cache_key_with_version, asset.s3_key], last_modified: asset.updated_at, public: true)

    send_data asset.data,
              type: asset.file_mime_type.presence || "application/octet-stream",
              filename: asset.file_name,
              disposition: "inline"
  end

  private
    def require_public_assets_enabled
      head :not_found unless Rails.application.config.folio_public_assets_enabled
    end
end
