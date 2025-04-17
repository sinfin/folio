# frozen_string_literal: true

class Folio::Api::S3Controller < Folio::Api::BaseController
  include Folio::S3::Client

  skip_before_action :verify_authenticity_token, only: [:uploaded, :processed]

  before_action :verify_file_class
  before_action :authenticate_s3!, except: [:uploaded, :processed]
  # before_action :get_file_name_and_s3_path, only: %i[before]

  # Creates pre-sign URL for uploading file to S3 upload path and create DB record for this file
  def before
    file_name = params.require(:file_name).split(".").map(&:parameterize).join(".")

    session[:init] = true unless session.id

    file = file_class.create!(
      file_name: file_name,
      reference_key: session.id.public_id,
      site: site_for_new_files,
      user: current_user
    )

    # return settings for S3 file upload
    presigned_url = test_aware_presign_url(file.full_s3_path, method_name: :put_object)

    render json: {
      file_uuid: file.file_uuid,
      s3_url: presigned_url,
      file_name: file.file_name,
    }
  end

  # somewhere between, JS on FE directly loads file as temporary to S3 and returns it's s3_path

  # Called after file is successfully uploaded to S3 upload path.
  # Just change file state to unprocessed
  def after
    file = file_class.find_by!(file_uuid: params.require(:file_uuid))

    # unless file
    #   head :not_found
    #   return
    # end

    file.process_uploaded

    head :ok
  end

  # Called when file is uploaded to S3 but not processed. Difference between uploaded and after is that after is called
  # by FE and uploaded is called by AWS
  def uploaded
    # TODO: add custom authorization by ApiToken

    after
  end

  # Called when any metadata was updated or created in AWS for requested file. This also means file is ready to use.
  # Called by lambda from AWS.
  def processed
    # TODO: add custom authorization by ApiToken

    file = file_class.find_by!(file_uuid: params.require(:file_uuid))

    # unless file
    #   head :not_found
    #   return
    # end

    file.process_metadata(JSON.parse(request.body.read), params[:fileLastModified])

    head :ok
  end

  # Folio::FileList::FileComponent created from a template waits for a message from the S3 job. Once it gets it, it will
  # ping this endpoint to get the render component with the file
  def file_list_file
    @file = file_class.accessible_by(Folio::Current.ability).find_by!(file_uuid: params.require(:file_uuid))

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
  end

  private
    def verify_file_class
      head :not_found unless file_class
    end

    def file_class
      return @file_class if defined?(@file_class)

      if params[:file_type]
        @file_class = Folio::Aws::FileJwt.file_subclass(params[:file_type].tr("-", "/").classify)
      else
        @file_class = Folio::Aws::FileJwt.file_subclass(params.require(:type))
      end
    end

    def authenticate_s3!
      return if Rails.application.config.folio_direct_s3_upload_allow_public
      return if can_now?(:create, file_class.new(site: Folio::Current.site))
      return if Rails.application.config.folio_direct_s3_upload_allow_for_users && user_signed_in?
      return if Rails.application.config.folio_allow_users_to_console && user_signed_in?
      fail CanCan::AccessDenied
    end

    def site_for_new_files
      Rails.application.config.folio_shared_files_between_sites ? Folio::Current.main_site : Folio::Current.site
    end
end
