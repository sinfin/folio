# frozen_string_literal: true

class Folio::Api::S3Controller < Folio::Api::BaseController
  include Folio::S3::Client

  before_action :authenticate_s3!
  # before_action :get_file_name_and_s3_path, only: %i[before]
  before_action :verify_file_class
  before_action :verify_jwt, except: [:before]

  # Creates pre-sign URL for uploading file to S3 upload path
  def before
    file_name = params.require(:file_name).split(".").map(&:parameterize).join(".")

    session[:init] = true unless session.id

    file = file_class.create!(
      file_name: file_name,
      reference_key: session.id.public_id,
      site: site_for_new_files
    )

    # return settings for S3 file upload
    presigned_url = test_aware_presign_url(file.upload_s3_path)

    render json: {
      jwt: Folio::Aws::FileJwt.encode(file.upload_jwt_payload),
      s3_url: presigned_url,
      file_name: file.file_name,
    }
  end

  # somewhere between, JS on FE directly loads file as temporary to S3 and returns it's s3_path

  # Called after file is successfully uploaded to S3 upload path.
  # Used for processing by Sidekiq
  def after
    file = file_class.find_by(file_id: jwt_payload["fid"])

    unless file
      head :not_found
      return
    end

    file.upload_done! if file.new?

    head :ok
  end

  # Called when any metadata was updated or created in AWS for file. This also means file is ready to use.
  # Called by lambda from AWS.
  def processed
    file = file_class.find_by(file_id: jwt_payload["fid"])

    unless file
      head :not_found
      return
    end

    file.metadata = JSON.parse(request.body.read)
    file.save!

    head :ok
  end

  # Folio::FileList::FileComponent created from a template waits for a message from the S3 job. Once it gets it, it will
  # ping this endpoint to get the render component with the file
  def file_list_file
    @file = file_class.accessible_by(Folio::Current.ability).find(jwt_payload["fid"])

    props = { file: @file }

    %i[
        editable
        destroyable
        selectable
      ].each do |param|
      if params[param]
        props[param] = params[param]
      end
    end

    if params[:primary_action].is_a?(String)
      props[:primary_action] = params[:primary_action].to_sym
    end

    render_component_json(Folio::FileList::FileComponent.new(**props))
  end

  private

    def verify_jwt
      head :not_found unless params[:jwt] && jwt_payload
    end

    def verify_file_class
      head :not_found unless file_class
    end

    def jwt_payload
      @jwt_payload ||= Folio::Aws::FileJwt.decode(params[:jwt])
    rescue JWT::DecodeError
      # TODO: maybe explicitly handle
      nil
    end

    def file_class
      return @file_class if defined?(@file_class)

      file_type = params[:jwt] ? jwt_payload["cn"] : params[:type]

      @file_class = (file_type ? Folio::Aws::FileJwt.file_subclass(file_type) : nil)
    end

    def authenticate_s3!
      return if Rails.application.config.folio_direct_s3_upload_allow_public
      return if can_now?(:create, file_class.new(site: Folio::Current.site))
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
      message_bus_client_id = params.require(:message_bus_client_id)

      if file_class && test_aware_s3_exists?(@s3_path)
        job_klass.perform_later(s3_path: @s3_path,
                                type: file_class.name,
                                message_bus_client_id:,
                                existing_id: params[:existing_id].try(:to_i),
                                web_session_id: session.id.public_id,
                                user_id: Folio::Current.user.try(:id),
                                attributes: Rails.application.config.folio_direct_s3_upload_attributes_for_job_proc.call(self))
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def site_for_new_files
      Rails.application.config.folio_shared_files_between_sites ? Folio::Current.main_site : Folio::Current.site
    end
end
