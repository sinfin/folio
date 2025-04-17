# frozen_string_literal: true

module Folio::Aws::FileProcessable
  extend ActiveSupport::Concern

  READY_STATE = :ready

  included do
    require "jwt"

    include Folio::HasAasmStates

    belongs_to :user, class_name: "Folio::User", foreign_key: :user_id, optional: true

    skip_nillify_for :metadata, :metadata_rekognition

    # Defaults for attributes to avoid validation or database errors
    attribute :metadata, :jsonb, default: {}
    attribute :metadata_rekognition, :jsonb, default: {}
    attribute :file_uuid, :uuid, default: -> { SecureRandom.uuid }

    after_initialize :set_defaults, if: :new_record?

    validates :file_uuid, :s3_path, presence: true
    validates :metadata, :metadata_rekognition, presence: true, allow_blank: true

    aasm do
      state :new, initial: true, color: :yellow
      state :unprocessed, color: :orange

      state READY_STATE, color: :green
      state :processing_failed, color: :red

      event :upload_done do
        transitions from: :new, to: :unprocessed

        # TODO: trigger worker that checks if file was processed in S3. In case we can't receive Notify BE lambda call
        #       like development environment
      end

      event :processing_done do
        transitions from: :unprocessed, to: READY_STATE
      end

      event :processing_failed do
        transitions from: :unprocessed, to: :processing_failed
      end

      event :reprocess do
        transitions from: READY_STATE, to: :unprocessed

        # TODO: increase version on itself
      end
    end
  end

  def set_defaults
    self.s3_base_path ||= "#{self.class.human_type}/#{file_uuid}/"
  end

  def s3_path
    "#{s3_base_path}/#{version}/#{file_name}"
  end

  def full_s3_path
    "#{Rails.env}/lambda_files/#{s3_path}"
  end

  def upload_s3_path(jwt_payload = upload_jwt_payload)
    "tmp_folio_file_uploads/#{Folio::Aws::FileJwt.encode(jwt_payload)}/#{file_name}"
  end

  def download_s3_path(jwt_payload = download_jwt_payload)
    # TODO: some base url path for cloudfront like /files/<jwt>/<file_name>
    "files/#{Folio::Aws::FileJwt.encode(jwt_payload)}/#{file_name}"
  end

  def upload_jwt_payload(metadata_endpoint: nil, skip_rekognition: false)
    payload = Folio::Aws::FileJwt::Payload.new(
      file_id: file_uuid,
      class_name: self.class.name,
      version: version,
      s3_path: full_s3_path,
      metadata_endpoint: metadata_endpoint
    )
    payload[:skip_rekognition] = skip_rekognition

    payload
  end

  # To send user session id with same domain:
  #    Rails.application.config.session_store :cookie_store, key: '_your_app_session', domain: :all, tld_length: 2, secure: Rails.env.production?
  # To get user session id:
  #    cookies[Rails.application.config.session_options[:key]]
  def download_jwt_payload(user_session_id: nil)
    raise "TODO: we need user for private session" if self.class == Folio::SessionAttachment && user_session_id.nil?

    payload = Folio::Aws::FileJwt::Payload.new(
      file_id: file_uuid,
      s3_path: full_s3_path,
      version: version
    )
    payload[:user_session_id] = user_session_id if user_session_id

    payload
  end
end
