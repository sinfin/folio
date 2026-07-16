# frozen_string_literal: true

class Folio::Api::S3Controller < Folio::Api::BaseController
  include Folio::S3::Client

  before_action :authenticate_s3!, except: %i[file_list_file]
  before_action :ensure_multipart_upload_enabled!, only: %i[
    create_multipart_upload
    sign_part
    complete_multipart_upload
    abort_multipart_upload
  ]
  before_action :get_file_name_and_s3_path, only: %i[before create_multipart_upload]
  before_action :get_existing_s3_path, only: %i[
    sign_part
    complete_multipart_upload
    abort_multipart_upload
  ]

  def before # return settings for S3 file upload
    presigned_url = test_aware_presign_url(s3_path: @s3_path, method_name: :put_object)

    render json: {
      jwt: "TODO",
      s3_url: presigned_url,
      file_name: @file_name,
      s3_path: @s3_path,
    }
  end

  def create_multipart_upload
    options = {
      bucket: s3_bucket,
      key: test_aware_s3_path(@s3_path),
    }

    options[:content_type] = params[:content_type] if params[:content_type].present?

    response = s3_client.create_multipart_upload(**options)

    render json: {
      uploadId: response.upload_id,
      upload_id: response.upload_id,
      key: @s3_path,
      s3_path: @s3_path,
      file_name: @file_name,
      jwt: "TODO",
    }
  end

  def sign_part
    presigned_url = s3_presigner.presigned_url(
      :upload_part,
      bucket: s3_bucket,
      key: test_aware_s3_path(@s3_path),
      upload_id: upload_id_param,
      part_number: part_number_param,
    )

    render json: { url: presigned_url }
  end

  def complete_multipart_upload
    response = s3_client.complete_multipart_upload(
      bucket: s3_bucket,
      key: test_aware_s3_path(@s3_path),
      upload_id: upload_id_param,
      multipart_upload: { parts: multipart_upload_parts },
    )

    render json: {
      location: response.try(:location),
      key: @s3_path,
      s3_path: @s3_path,
    }
  end

  def abort_multipart_upload
    s3_client.abort_multipart_upload(
      bucket: s3_bucket,
      key: test_aware_s3_path(@s3_path),
      upload_id: upload_id_param,
    )

    render json: {}
  end

  # somewhere between, JS on FE directly loads file as temporary to S3 and returns it's s3_path

  def after # load back file from S3 and process it
    handle_after(Folio::S3::CreateFileJob)
  end

  # Folio::FileList::FileComponent created from a template waits for a message from the S3 job. Once it gets it, it will ping this endpoint to get the render component with the file
  def file_list_file
    fail CanCan::AccessDenied unless can_now?(:access_console)

    file_type = params.require(:file_type)
    file_klass = file_type.safe_constantize

    if file_klass && allowed_klass?(file_klass)
      @file = file_klass.accessible_by(Folio::Current.ability).find(params.require(:file_id))

      props = { file: @file }

      %i[
        editable
        destroyable
        selectable
        batch_actions
      ].each do |param|
        if params[param]
          props[param] = params[param].in? ["true", true]
        end
      end

      add_to_batch = file_klass < Folio::File && params[:add_to_batch].in?(["true", true])

      meta = if add_to_batch
        { reload_batch_bar: true }
      end

      if add_to_batch
        batch_service = Folio::Console::Files::BatchService.new(session_id: session.id.public_id,
                                                                file_class_name: file_klass.to_s)
        batch_service.add_file(@file.id)
        batch_service.set_form_open(true)
      end

      if params[:primary_action].is_a?(String)
        props[:primary_action] = params[:primary_action].to_sym
      end

      render_component_json(Folio::FileList::FileComponent.new(**props), meta:)
    else
      render json: {}, status: 404
    end
  end

  private
    def allowed_klass?(file_klass)
      Rails.application.config.folio_direct_s3_upload_class_names.any? do |class_name|
        file_klass <= class_name.constantize
      end
    end

    def authenticate_s3!
      return if Rails.application.config.folio_direct_s3_upload_allow_public
      return if can_now?(:create, Folio::File.new(site: Folio::Current.site))
      return if Rails.application.config.folio_direct_s3_upload_allow_for_users && user_signed_in?
      return if Rails.application.config.folio_allow_users_to_console && user_signed_in?
      fail CanCan::AccessDenied
    end

    def get_file_name_and_s3_path
      @file_name = params.require(:file_name).split(".").map(&:parameterize).join(".")

      session[:init] = true unless session.id

      @s3_path = [
        "tmp_folio_file_uploads",
        "session",
        session.id.public_id,
        SecureRandom.urlsafe_base64(16),
        @file_name,
      ].join("/")
    end

    def get_existing_s3_path
      @s3_path = params[:key].presence || params[:s3_path].presence

      unless @s3_path&.start_with?(s3_upload_path_prefix)
        render json: {}, status: :unprocessable_content
      end
    end

    def s3_upload_path_prefix
      "tmp_folio_file_uploads/session/"
    end

    def s3_upload_session_prefix
      session[:init] = true unless session.id

      [
        s3_upload_path_prefix.delete_suffix("/"),
        session.id.public_id,
        "",
      ].join("/")
    end

    def ensure_multipart_upload_enabled!
      render json: {}, status: :not_found unless Rails.application.config.folio_direct_s3_multipart_upload_enabled
    end

    def upload_id_param
      params[:uploadId].presence || params[:upload_id].presence || params.require(:upload_id)
    end

    def part_number_param
      part_number = (params[:partNumber].presence || params[:part_number].presence || params.require(:part_number)).to_i

      if part_number < 1 || part_number > 10_000
        raise ActionController::BadRequest, "Invalid S3 multipart part number"
      end

      part_number
    end

    def multipart_upload_parts
      params.require(:parts).map do |part|
        {
          part_number: (part[:PartNumber].presence || part[:part_number].presence || part[:partNumber]).to_i,
          etag: part[:ETag].presence || part[:etag],
        }
      end
    end

    def handle_after(job_klass)
      @s3_path = params.require(:s3_path)
      type = params.require(:type)
      message_bus_client_id = params.require(:message_bus_client_id)
      file_klass = type.safe_constantize

      if file_klass && allowed_klass?(file_klass) && test_aware_s3_exists?(s3_path: @s3_path)
        job_klass.perform_later(s3_path: @s3_path,
                                type:,
                                message_bus_client_id:,
                                existing_id: params[:existing_id].try(:to_i),
                                web_session_id: session.id.public_id,
                                user_id: Folio::Current.user.try(:id),
                                attributes: Rails.application.config.folio_direct_s3_upload_attributes_for_job_proc.call(self))
        render json: {}
      else
        render json: {}, status: 422
      end
    end

    def site_for_new_files
      Folio::File.correct_site(Folio::Current.site)
    end
end
