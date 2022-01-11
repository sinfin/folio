# frozen_string_literal: true

require "tempfile"
require "zip"

module Folio::Console::Api::FileControllerBase
  extend ActiveSupport::Concern
  include Folio::S3Client

  def index
    can_cache = (params[:page].nil? || params[:page] == "1") &&
                filter_params.to_h.all? { |k, v| v.blank? }

    if can_cache
      json = Rails.cache.fetch(index_cache_key, expires_in: 1.day) do
        index_json
      end
    else
      json = index_json
    end

    render json: json
  end

  def s3_before # return settings for S3 file upload
    file_name = params.require(:file_name).split(".").map(&:parameterize).join(".")

    session[:init] = true unless session.id

    letters = ("a".."z").to_a.sample(2)

    s3_path = [
      "tmp_folio_file_uploads",
      "session",
      session.id.public_id,
      SecureRandom.urlsafe_base64(16),
      file_name,
    ]

    s3_path = s3_path.join("/")

    presigned_url = test_aware_presign_url(s3_path)

    render json: { s3_url: presigned_url, file_name: file_name, s3_path: s3_path }
  end

  # somewhere between, JS on FE directly loads file to S3 and returns it's s3_path

  def s3_after # load back file from S3 and process it
    s3_path = params.require(:s3_path)
    type = params.require(:type).safe_constantize

    if type && type < Folio::File && test_aware_s3_exists?(s3_path)
      Folio::CreateFileFromS3Job.perform_later(s3_path: s3_path, type: type)
      render json: {}
    else
      render json: {}, status: 422
    end
  end

  def update
    if folio_console_record.update(file_params)
      meta = {
        flash: {
          success: t("flash.actions.update.notice", resource_name: @klass.model_name.human)
        }
      }
    else
      meta = {
        flash: {
          alert: t("flash.actions.update.alert", resource_name: @klass.model_name.human)
        }
      }
    end

    render_record(folio_console_record, Folio::Console::FileSerializer, meta: meta)
  end

  def destroy
    folio_console_record.destroy!
    render json: { status: 200 }
  end

  def tag
    tag_params = params.permit(:author, :description, file_ids: [], tags: [])

    files = Folio::File.where(id: tag_params[:file_ids])

    Folio::File.transaction do
      files.each { |f| f.update!(tag_list: tag_params[:tags],
                                 author: tag_params[:author],
                                 description: tag_params[:description]) }
    end

    render_records(files, Folio::Console::FileSerializer)
  end

  def mass_destroy
    ids = params.require(:ids).split(",")
    @klass.where(id: ids).each(&:destroy!)
    render json: { data: { message: t(".success") }, status: 200 }
  rescue StandardError => e
    render json: { error: t(".failure", msg: e.message), status: 400 }
  end

  def change_file
    old_thumbnail_versions = folio_console_record.thumbnail_sizes.dup

    if folio_console_record.update(file_params.to_h.merge(thumbnail_sizes: {}))
      if folio_console_record.is_a?(Folio::Image)
        Folio::DeleteThumbnailsJob.perform_later(old_thumbnail_versions)

        old_thumbnail_versions.keys.each do |version|
          folio_console_record.thumb(version)
        end
      end

      meta = {
        flash: {
          success: t("flash.actions.update.notice", resource_name: @klass.model_name.human)
        }
      }
    else
      meta = {
        flash: {
          alert: t("flash.actions.update.alert", resource_name: @klass.model_name.human)
        }
      }
    end

    render_record(folio_console_record,
                  Folio::Console::FileSerializer,
                  meta: meta)
  end

  def mass_download
    ids = params.require(:ids).split(",")
    files = @klass.where(id: ids)

    tmp_zip_file = Tempfile.new("folio-files")

    Zip::File.open(tmp_zip_file.path, Zip::File::CREATE) do |zip|
      files.each do |file|
        # dragonfly ¯\_(ツ)_/¯
        tmp_file = file.file.file
        zip.add("#{file.id}-#{file.file_name}", tmp_file)
      end
    end

    zip_data = File.read(tmp_zip_file.path)
    send_data(zip_data, type: "application/zip",
                        filename: "#{@klass.model_name.human(count: 2)}-#{Time.zone.now.to_i}.zip")
  end

  private
    def folio_console_collection_includes
      [:tags, :file_placements]
    end

    def filter_params
      params.permit(:by_file_name, :by_placement, :by_tags, :by_used)
    end

    def file_params
      p = params.require(:file)
                .require(:attributes)
                .permit(:tag_list,
                        :type,
                        :file,
                        :author,
                        :description,
                        :sensitive_content,
                        tags: [])

      if p[:tags].present? && p[:tag_list].blank?
        p[:tag_list] = p.delete(:tags).join(",")
      end

      p
    end

    def index_json
      pagination, records = pagy(folio_console_records.ordered, items: 60)
      meta = meta_from_pagy(pagination).merge(react_type: @klass.react_type)

      json_from_records(records, Folio::Console::FileSerializer, meta: meta)
    end

    def index_cache_key
      "folio/console/api/file/#{@klass.model_name.plural}/index/#{@klass.count}/#{@klass.maximum(:updated_at)}"
    end
end
