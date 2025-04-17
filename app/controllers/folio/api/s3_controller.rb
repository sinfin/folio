# frozen_string_literal: true

class Folio::Api::S3Controller < Folio::Api::BaseController
  include Folio::S3::Client

  before_action :authenticate_s3!
  # before_action :get_file_name_and_s3_path, only: %i[before]
  before_action :verify_file_class

  # Creates pre-sign URL for uploading file to S3 upload path and create DB record for this file
  def before
    file_name = params.require(:file_name).split(".").map(&:parameterize).join(".")

    session[:init] = true unless session.id

    file = file_class.create!(
      file_name: file_name,
      reference_key: session.id.public_id,
      site: site_for_new_files
    )

    # return settings for S3 file upload
    presigned_url = test_aware_presign_url(file.s3_path)

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

    file.upload_done! if file.initialized?

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

    if file.uploaded?
      file.metadata = JSON.parse(request.body.read)
      file.processing_done!
      file.save!
    end

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

      @file_class = Folio::Aws::FileJwt.file_subclass(params.require(:type))
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
