# frozen_string_literal: true

class Folio::Api::S3Controller < Folio::Api::BaseController
  include Folio::S3::Client

  before_action :authenticate_s3!
  before_action :get_file_name_and_s3_path, only: %i[before]

  def before # return settings for S3 file upload
    presigned_url = test_aware_presign_url(s3_path: @s3_path)

    render json: {
      s3_url: presigned_url,
      file_name: @file_name,
      s3_path: @s3_path,
    }
  end

  # somewhere between, JS on FE directly loads file as temporary to S3 and returns it's s3_path

  def after # load back file from S3 and process it
    handle_after(Folio::S3::CreateFileJob)
  end

  # Folio::FileList::FileComponent created from a template waits for a message from the S3 job. Once it gets it, it will ping this endpoint to get the render component with the file
  def file_list_file
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
          props[param] = params[param]
        end
      end

      if params[:primary_action].is_a?(String)
        props[:primary_action] = params[:primary_action].to_sym
      end

      render_component_json(Folio::FileList::FileComponent.new(**props))
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
      Rails.application.config.folio_shared_files_between_sites ? Folio::Current.main_site : Folio::Current.site
    end
end
