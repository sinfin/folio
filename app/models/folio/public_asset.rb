# frozen_string_literal: true

class Folio::PublicAsset < Folio::ApplicationRecord
  include Folio::BelongsToSite

  attr_reader :file

  belongs_to :created_by_folio_user, class_name: "Folio::User", optional: true

  before_validation :set_file_metadata, if: -> { file.present? }
  before_validation :set_token, on: :create
  before_save :store_file, if: -> { file.present? }
  before_update :remember_previous_key, if: :s3_key_changed?
  after_commit :finish_upload, on: %i[create update]
  after_rollback :discard_upload
  after_destroy_commit :destroy_file

  validates :token, :file_name, :file_mime_type, :file_size, presence: true
  validates :file, presence: true, if: -> { s3_key.blank? }

  scope :ordered, -> { order(created_at: :desc, id: :desc) }
  scope :by_query, -> (query) { where("file_name ILIKE ?", "%#{sanitize_sql_like(query)}%") }
  scope :created_by_current_user, -> (_value = true) { where(created_by_folio_user_id: Folio::Current.user&.id) }

  def file=(upload)
    @file = upload.presence
  end

  def to_label
    file_name
  end

  def public_url
    Folio::Engine.routes.url_helpers.public_asset_url(token:,
                                                      host: site.env_aware_domain,
                                                      protocol: site.env_aware_root_url.split(":").first)
  end

  def data
    storage.read(key: s3_key)
  end

  private
    def storage
      @storage ||= Folio::PublicAssets::Storage.new
    end

    def set_token
      self.token ||= SecureRandom.uuid
    end

    def set_file_metadata
      self.file_name = File.basename(file.original_filename)
      self.file_size = file.size
      self.file_mime_type = Marcel::MimeType.for(Pathname.new(file.path), name: file_name)
    end

    def store_file
      @uploaded_key = storage.write(upload: file, token:, file_name:, mime_type: file_mime_type)
      self.s3_key = @uploaded_key
    end

    def remember_previous_key
      @previous_key = s3_key_in_database
    end

    def finish_upload
      storage.delete(key: @previous_key) if @previous_key.present?
      @previous_key = @uploaded_key = @file = nil
    end

    def discard_upload
      storage.delete(key: @uploaded_key) if @uploaded_key.present?
      @previous_key = @uploaded_key = @file = nil
    end

    def destroy_file
      storage.delete(key: s3_key) if s3_key.present?
    end
end
