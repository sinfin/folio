# frozen_string_literal: true

require "tempfile"
require "zip"

module Folio::Console::Api::FileControllerBase
  extend ActiveSupport::Concern

  S3_PATH_DOWNLOAD_BASE = "tmp/folio-files-batch-download"

  included do
    include Folio::S3::Client
    before_action :set_safe_file_ids, only: %i[batch_delete batch_download batch_update batch_download_success]
    before_action :delete_s3_download_file, only: %i[handle_batch_queue batch_delete cancel_batch_download]
  end

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

    render json:
  end

  def show
    fail CanCan::AccessDenied unless can_now?(:show, folio_console_record)

    render_component_json(Folio::Console::Files::ShowComponent.new(file: folio_console_record),
                          meta: { title: folio_console_record.to_label })
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

    render_record(folio_console_record, Folio::Console::FileSerializer, meta:)
  end

  def destroy
    folio_console_record.destroy!
    render json: { status: 200 }
  end

  def tag
    tag_params = params.permit(:author, :description, :alt, file_ids: [], tags: [])

    files = Folio::File.where(id: tag_params[:file_ids])

    Folio::File.transaction do
      files.each do |f|
        f.update!(tag_list: tag_params[:tags],
                  author: tag_params[:author],
                  description: tag_params[:description],
                  alt: tag_params[:alt])
      end
    end

    render_records(files, Folio::Console::FileSerializer)
  end

  def pagination
    @pagy, _records = pagy(folio_console_records, items: Folio::Console::FileControllerBase::PAGY_ITEMS)

    @pagy_options = {
      reload_url: url_for([:pagination, :console, :api, @klass, page: params[:page]])
    }

    if @klass.human_type == "image"
      @pagy_options[:middle_component] = Folio::Console::Files::DisplayToggleComponent.new
    end

    render_component_json(Folio::Console::Ui::PagyComponent.new(pagy: @pagy,
                                                                options: @pagy_options))
  end

  def handle_batch_queue
    queue = params.require(:queue)
    queue_add = queue[:add].is_a?(Array) ? Array(queue[:add]).map(&:to_i) : []
    queue_remove = queue[:remove].is_a?(Array) ? Array(queue[:remove]).map(&:to_i) : []

    persisted_file_ids = folio_console_records.where(id: queue_add + queue_remove).pluck(:id)

    batch_service.handle_queue(queue_add, queue_remove, persisted_file_ids)

    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def batch_bar
    render_batch_bar_component
  end

  def open_batch_form
    batch_service.set_form_open(true)
    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def close_batch_form
    batch_service.set_form_open(false)
    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def batch_download_success
    download_hash = batch_service.get_download_status

    if download_hash && download_hash["pending"] && download_hash["timestamp"] && params[:url]
      new_status = { "url" => params[:url], "timestamp" => download_hash["timestamp"] }
      batch_service.set_download_status(new_status)
    end

    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def batch_download_failure
    download_hash = batch_service.get_download_status

    if download_hash && download_hash["pending"] && download_hash["timestamp"] && params[:message]
      new_status = { "failure_message" => params[:message], "timestamp" => download_hash["timestamp"] }
      batch_service.set_download_status(new_status)
    end

    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def cancel_batch_download
    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def batch_download
    if @safe_file_ids.blank?
      raise ActionController::BadRequest.new("Invalid file IDs - no files selected")
    end

    file_name = "#{Folio::Current.site.slug}-#{@klass.human_type.pluralize}.zip"
    s3_path = "#{S3_PATH_DOWNLOAD_BASE}/#{Time.current.to_i}-#{SecureRandom.hex(8)}/#{file_name}"

    Folio::File::BatchDownloadJob.perform_later(s3_path:,
                                                file_ids: @safe_file_ids,
                                                file_class_name: @klass.to_s,
                                                user_id: Folio::Current.user.id,
                                                site_id: Folio::Current.site.id)

    download_status = { "pending" => true, "timestamp" => Time.current.to_i, "s3_path" => s3_path }
    batch_service.set_download_status(download_status)

    dispatch_batch_bar_message
    render_batch_bar_component
  end

  def batch_delete
    files = @klass.where(id: @safe_file_ids).to_a

    if indestructible_file = files.find { |file| file.indestructible_reason }
      raise ActionController::BadRequest.new(indestructible_file.indestructible_reason)
    end

    if forbidden_file = files.find { |file| !can_now?(:destroy, file) }
      raise ActionController::BadRequest.new("Invalid file IDs - you are not allowed to destroy file #{forbidden_file.id}")
    end

    @klass.transaction do
      files.each { |file| file.destroy! }
    end

    batch_service.clear_files
    batch_service.set_form_open(false)

    dispatch_batch_bar_message
    render_batch_bar_component(change_to_propagate: { change: "delete", file_ids: @safe_file_ids },
                               flash: { success: t("folio.console.api.file_controller_base.batch_delete_success") })
  end

  def batch_update
    files = @klass.where(id: @safe_file_ids)

    if forbidden_file = files.find { |file| !can_now?(:update, file) }
      raise ActionController::BadRequest.new("Invalid file IDs - you are not allowed to update file #{forbidden_file.id}")
    end

    update_params = params.require(:file_attributes)
                          .permit(:author,
                                  :attribution_source,
                                  :attribution_source_url,
                                  :attribution_copyright,
                                  :attribution_licence,
                                  :alt,
                                  :tag_list,
                                  :headline,
                                  :description)
                          .to_h
                          .select { |_, value| value.present? }

    @klass.transaction do
      files.each { |file| file.update!(update_params) }
    end

    batch_service.set_form_open(false)

    dispatch_batch_bar_message
    render_batch_bar_component(change_to_propagate: { change: "update", file_ids: @safe_file_ids },
                               flash: { success: t("folio.console.api.file_controller_base.batch_update_success") })
  end

  def file_picker_file_hash
    render_record(folio_console_record, Folio::Console::FileSerializer)
  end

  def extract_metadata
    return render(json: { error: "Not supported for this file type" }, status: 422) unless folio_console_record.respond_to?(:extract_metadata!)

    # Force re-extraction synchronously for immediate UI feedback
    if folio_console_record.respond_to?(:extract_metadata!)
      # Run synchronous extraction with force flag
      folio_console_record.extract_metadata!(force: true, user_id: Folio::Current.user&.id)
      folio_console_record.reload

      # Broadcast for live UI update (MessageBus JSON payload)
      broadcast_metadata_extracted(folio_console_record)

      render_record(folio_console_record, Folio::Console::FileSerializer, meta: {
        flash: {
          success: t("folio.console.files.metadata_extracted")
        }
      })
    else
      render json: { error: "Metadata extraction not available" }, status: 422
    end
  rescue => e
    Rails.logger.error "Metadata extraction failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: t("folio.console.files.metadata_extraction_failed") }, status: 500
  end

  private
    def folio_console_collection_includes
      [:tags, :file_placements]
    end

    def filter_params
      params.permit(:by_file_name, :by_placement, :by_tags, :by_used, :by_photo_archive)
    end

    def file_params_whitelist
      ary = [
        :tag_list,
        :type,
        :file,
        :author,
        :attribution_source,
        :attribution_source_url,
        :attribution_copyright,
        :attribution_licence,
        :description,
        :sensitive_content,
        :default_gravity,
        :alt,
        # IPTC Core metadata fields (writable)
        :headline,
        :capture_date,
        :gps_latitude,
        :gps_longitude,
        :file_metadata_extracted_at
      ]

      test_instance = @klass.new

      if test_instance.try(:console_show_additional_fields).present?
        ary += test_instance.console_show_additional_fields.keys
      end

      ary << { tags: [] }

      ary
    end

    def file_params
      p = params.require(:file)
                  .require(:attributes)
                  .permit(*file_params_whitelist)

      if p[:tags].present? && p[:tag_list].blank?
        p[:tag_list] = p.delete(:tags).join(",")
      end

      p
    end

    def broadcast_metadata_extracted(file)
      return unless defined?(MessageBus)
      return unless Folio::Current.user

      begin
        serialized = Folio::Console::FileSerializer.new(file).serializable_hash
        attrs = serialized[:data][:attributes]
      rescue
        attrs = {}
      end

      message_data = {
        type: "Folio::File::MetadataExtracted",
        file: {
          id: file.id,
          type: file.class.name,
          attributes: attrs
        }
      }

      MessageBus.publish(Folio::MESSAGE_BUS_CHANNEL, message_data.to_json, user_ids: [Folio::Current.user.id])
    end

    def index_json
      pagination, records = pagy(folio_console_records.ordered, items: 60)
      meta = meta_from_pagy(pagination).merge(human_type: @klass.human_type)

      json_from_records(records, Folio::Console::FileSerializer, meta:)
    end

    def index_cache_key
      "folio/console/api/site/#{Folio::Current.site.id}/file/#{@klass.model_name.plural}/index/#{@klass.count}/#{@klass.maximum(:updated_at)}"
    end

    def allowed_record_sites
      if Rails.application.config.folio_shared_files_between_sites
        [Folio::Current.main_site, Folio::Current.site]
      else
        [Folio::Current.site]
      end
    end

    def set_safe_file_ids
      batch_file_ids = batch_service.get_file_ids
      param_file_ids = params.require(:file_ids)

      if param_file_ids.is_a?(Array)
        param_file_ids.map!(&:to_i)
      else
        raise ActionController::BadRequest.new("Invalid file IDs")
      end

      safe_file_ids = param_file_ids & batch_file_ids

      if safe_file_ids.size != param_file_ids.size
        raise ActionController::BadRequest.new("Invalid file IDs")
      end

      @safe_file_ids = safe_file_ids
    end

    def delete_s3_download_file
      download_hash = batch_service.get_download_status
      return unless download_hash.is_a?(Hash)

      if download_hash["s3_path"].is_a?(String)
        run_delete_s3_job(s3_path: download_hash["s3_path"])
      end

      batch_service.set_download_status(nil)
    end

    def run_delete_s3_job(s3_path:, wait: nil)
      return unless s3_path.start_with?(S3_PATH_DOWNLOAD_BASE)

      job = Folio::S3::DeleteJob
      job = job.set(wait:) if wait
      job.perform_later(s3_path:)
    end

    def batch_service
      @batch_service ||= Folio::Console::Files::BatchService.new(session_id: session.id.public_id,
                                                                 file_class_name: @klass.to_s)
    end

    def dispatch_batch_bar_message
      if Folio::Current.user
        @batch_bar_updated_at = Time.current

        MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                           {
                             type: "Folio::Console::Files::Batch::BarComponent/reload",
                             data: {
                              updated_at: @batch_bar_updated_at.iso8601,
                             }
                           }.to_json,
                           user_ids: [Folio::Current.user.id]
      end
    end

    def render_batch_bar_component(flash: nil, change_to_propagate: nil)
      component = Folio::Console::Files::Batch::BarComponent.new(file_klass: @klass,
                                                                 updated_at: @batch_bar_updated_at || Time.current,
                                                                 multi_picker:  params[:multi_picker] == "1",
                                                                 change_to_propagate:)

      render_component_json(component, flash:)
    end
end
