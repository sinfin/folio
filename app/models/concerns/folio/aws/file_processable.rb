# frozen_string_literal: true

module Folio::Aws::FileProcessable
  extend ActiveSupport::Concern

  READY_STATE = :ready

  included do
    require "jwt"

    include Folio::HasAasmStates

    belongs_to :user, class_name: "Folio::User", foreign_key: :user_id, optional: true

    # Defaults for attributes to avoid validation or database errors
    attribute :metadata, :jsonb, default: {}
    attribute :metadata_rekognition, :jsonb, default: {}
    attribute :file_uuid, :uuid, default: -> { SecureRandom.uuid }

    after_initialize :set_defaults, if: :new_record?

    validates :file_uuid, :s3_path, presence: true
    validates :metadata, :metadata_rekognition, presence: true, allow_blank: true

    scope :by_state, ->(state) { where(aasm_state: state) }
    scope :visible, -> { where.not(aasm_state: [:initialized, :unprocessed]) }

    aasm do
      state :initialized, initial: true, color: :yellow
      state :uploaded, color: :orange

      state READY_STATE, color: :green
      state :processing_failed, color: :red

      event :upload_done do
        transitions from: :initialized, to: :uploaded

        # TODO: trigger worker that checks if file was processed in S3. In case we can't receive Notify BE lambda call
        #       like development environment
      end

      event :processing_done do
        transitions from: :uploaded, to: READY_STATE
      end

      event :processing_failed do
        transitions from: :uploaded, to: :processing_failed
      end

      event :reprocess do
        transitions from: READY_STATE, to: :uploaded

        # TODO: increase version on itself
      end
    end
  end

  def set_defaults
    self.s3_path ||= "uploads/#{self.class.human_type}/#{Time.now.strftime("%Y/%m/%d")}/#{file_uuid}"
  end

  # To send user session id with same domain:
  #    Rails.application.config.session_store :cookie_store, key: '_your_app_session', domain: :all, tld_length: 2, secure: Rails.env.production?
  # To get user session id:
  #    cookies[Rails.application.config.session_options[:key]]
  def download_s3_path(thumbor_url_part = nil)
    "files/#{file_name}?jwt=#{Folio::Aws::FileJwt.encode(file_uuid: file_uuid, s3_path: s3_path)}"
  end
end
