# frozen_string_literal: true

class Folio::Api::S3SignerController < Folio::Api::BaseController
  include Folio::S3Client

  before_action :authenticate_s3_signer!

  def s3_before # return settings for S3 file upload
    file_name = params.require(:file_name).split(".").map(&:parameterize).join(".")

    session[:init] = true unless session.id

    s3_path = [
      "tmp_folio_file_uploads",
      "session",
      session.id.public_id,
      SecureRandom.urlsafe_base64(16),
      file_name,
    ]

    s3_path = s3_path.join("/")

    presigned_url = test_aware_presign_url(s3_path)

    render json: { s3_url: presigned_url, file_name:, s3_path: }
  end

  # somewhere between, JS on FE directly loads file to S3 and returns it's s3_path

  def s3_after # load back file from S3 and process it
    s3_path = params.require(:s3_path)
    type = params.require(:type)
    file_klass = type.safe_constantize

    if file_klass && allowed_klass?(file_klass) && test_aware_s3_exists?(s3_path)
      Folio::CreateFileFromS3Job.perform_later(s3_path:, type:, existing_id: params[:existing_id].try(:to_i))
      render json: {}
    else
      render json: {}, status: 422
    end
  end

  private
    def allowed_klass?(file_klass)
      Rails.application.config.folio_direct_s3_upload_class_names.any? do |class_name|
        file_klass <= class_name.constantize
      end
    end

    def authenticate_s3_signer!
      return if Rails.application.config.folio_direct_s3_upload_allow_public
      return if current_account
      return if Rails.application.config.folio_direct_s3_upload_allow_for_users && user_signed_in?
      fail CanCan::AccessDenied
    end
end
