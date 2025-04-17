# frozen_string_literal: true

module Folio::Aws::FileProcessable
  extend ActiveSupport::Concern

  READY_STATE = :ready
  NON_TERMINAL_STATES = [:initialized, :unprocessed]

  REKOGNITION_MIME_TYPES = %w[image/jpeg image/png video/mp4 video/mov]

  module AwsS3File
    NAME = "file"
    METADATA = "metadata.json"
    REKOGNITION = "rekognition.metadata.json"
  end

  included do
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

    # Success flow:
    #   initialized -> unprocessed -> ready
    # Failed flow:
    #   initialized -> unprocessed -> processing_failed
    # Reprocess flow:
    #   ready -> unprocessed -> ready
    #   processing_failed -> unprocessed -> ready
    aasm do
      # Initial state when record is created. It also triggers Folio::Aws::CheckUploadedJob in development environment.
      state :initialized, initial: true, color: :yellow, after_enter: proc {
        check_aws_file(Folio::Aws::CheckUploadedJob)
      }
      state :unprocessed, color: :orange
      state READY_STATE, color: :green
      state :processing_failed, color: :red

      # When file is successfully uploaded to S3. Notification can come from AWS or can be triggerred by
      # Folio::Aws::CheckUploadedJob in development environment. It triggers Folio::Aws::CheckMetadataJob in
      # development.
      event :upload_done do
        transitions from: :initialized, to: :unprocessed

        after do
          check_aws_file(Folio::Aws::CheckMetadataJob)
        end
      end

      # When metadata.json was successfully created in S3. Notification can come from AWS or can be triggerred by
      # Folio::Aws::CheckMetadataJob in development environment. It notifies processing lamba in AWS through SQS if
      # necessary and triggers Folio::Aws::CheckRekognitionJob in development environment.
      event :processing_done do
        transitions from: :unprocessed, to: READY_STATE

        after do
          notify_aws_processing_lambda
        end
      end

      # When processing metadata failed. For example mime type of the file is not compatible with model type.
      event :processing_failed do
        transitions from: :unprocessed, to: :processing_failed
      end

      # By triggering this we will create new metadata.json and rekognition.metadata.json and overwrite old one in DB!
      event :reprocess do
        transitions from: [READY_STATE, :processing_failed], to: :unprocessed

        after do
          Folio::Aws::Sqs::UploadLambdaService.reprocess_metadata(full_s3_path)
          check_aws_file(Folio::Aws::CheckMetadataJob)
        end
      end
    end
  end

  class_methods do
    # List of valid mime types for this model. Children should overwrite this method
    #
    # @return [Array{String}] List of mime types
    def valid_mime_types
      []
    end
  end

  # Sets s3_path where file is/will be located
  def set_defaults
    self.s3_path ||= "uploads/#{Time.now.strftime("%Y/%m/%d")}/#{self.class.name.underscore.tr('/', '-')}/#{file_uuid}"
  end

  def notify_aws_processing_lambda
    # TODO: we want to run bellow in some cases
    options = {}

    # TODO: implement better logic to trigger rekognition lambda
    if REKOGNITION_MIME_TYPES.include?(file_mime_type)
      options[:rekognition] = true
      # check_aws_file(Folio::Aws::CheckRekognitionJob)
    end

    # Folio::Aws::Sqs::ProcessingLambdaService.process_s3_file(full_s3_path, file_mime_type, options)
  end

  # Creates job for checking file existence (or it's update) in S3 in development environment
  #
  # @param [Class] job_class
  def check_aws_file(job_class)
    return unless Rails.env.development?

    job_class.perform_later(self.class, file_uuid)
  end

  # Builds url for getting AWS file
  #
  # @param [String] thumbor URL part for Thumbor lambda
  # @param [Number] expires_at When token expires as linux timestamp
  # @param [Number] expires_in When token expires in future in seconds (this has higher priority than expires_at)
  #
  # @return [String] URI to get file
  def download_s3_path(thumbor: nil, expires_at: nil, expires_in: nil)
    jwt_payload = {
      file_uuid: file_uuid,
      s3_path: full_s3_path,
      thumbor: thumbor
    }.tap do |p|
      p[:exp] = expires_at if expires_at
      p[:exp] = Time.now.to_i + expires_in if expires_in
    end

    "#{self.class.human_type}/#{file_name}?jwt=#{Folio::Aws::FileJwt.encode(jwt_payload)}"
  end

  def process_uploaded
    return unless initialized?

    upload_done!
  end

  # Process metadata JSON given from AWS or job.
  #
  # @param [Hash] metadata_json metadata JSON
  # @param [Time] file_last_modified last modified time of metadata file
  def process_metadata(metadata_json, file_last_modified)
    return unless unprocessed?

    metadata_json["metafileTimestamp"] = file_last_modified

    self.metadata = metadata_json
    # TODO: do something if contentType is nil? It means lambda was not able to recognize type from file data (like zip
    #       or any plain text file)
    self.file_mime_type = metadata["contentType"] || metadata["uploadedContentType"]

    if valid_mime_type?
      processing_done!
    else
      # TODO: maybe add some reason somewhere or custom state
      processing_failed!
    end
  end

  # Process Rekognition metadata JSON given from AWS or job.
  #
  # @param [Hash] rekognition_json Rekognition metadata JSON
  # @param [Time] file_last_modified last modified time of metadata file
  def process_rekognition(rekognition_json, file_last_modified)
    # TODO: improve implementation?
    rekognition_json["metafileTimestamp"] = file_last_modified

    self.metadata_rekognition = rekognition_json
    self.save!
  end

  def valid_mime_type?
    # TODO: this needs better check but for now just compare model type with content general type. Probably explicitly
    #       check against list of valid mime types per model. So this should probably contain only raise "needs to be
    #       overwritten in model" or check against empty array
    # return self.class.valid_mime_types.include?(file_mime_type&.downcase)

    file_mime_type&.split("/")&.first == self.class.human_type
  end

  # Returns full S3 path to given file
  #
  # @param [String] file
  # @return [String] full path to given file
  def full_s3_path(file = AwsS3File::NAME)
    "#{s3_path}/#{file}"
  end
end
