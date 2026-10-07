# frozen_string_literal: true

class Folio::File::PublicAsset < Folio::File
  before_validation :set_public_asset_token, on: :create
  before_validation :set_public_asset_mime_type, if: :file_uid_changed?

  validates :public_asset_token, presence: true

  def public_url
    Folio::Engine.routes.url_helpers.public_asset_url(token: public_asset_token,
                                                      host: site.env_aware_domain,
                                                      protocol: site.env_aware_root_url.split(":").first)
  end

  def source_payload(intent: :cacheable)
    { url: public_url, mime_type: file_mime_type, cacheable: true }
  end

  private
    def set_correct_site
      # Existing public URLs must keep their original site when files are shared.
      super if new_record?
    end

    def set_public_asset_token
      self.public_asset_token ||= SecureRandom.uuid
    end

    def set_public_asset_mime_type
      self.file_mime_type = Marcel::MimeType.for(Pathname.new(file.path), name: file.name) if file
    end
end
