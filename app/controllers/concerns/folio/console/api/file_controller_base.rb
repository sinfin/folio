# frozen_string_literal: true

require "tempfile"
require "zip"

module Folio::Console::Api::FileControllerBase
  extend ActiveSupport::Concern

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
                        filename: "#{@klass.model_name.human(count: 2)}-#{Time.current.to_i}.zip")
  end

  def pagination
    @pagy, _records = pagy(folio_console_records, items: Folio::Console::FileControllerBase::PAGY_ITEMS)

    @pagy_options = {
      reload_url: url_for([:pagination, :console, :api, @klass, page: params[:page]])
    }

    if @klass.human_type == "image"
      @pagy_options = {
        middle_component: Folio::Console::Files::DisplayToggleComponent.new,
      }
    end

    render_component_json(Folio::Console::Ui::PagyComponent.new(pagy: @pagy,
                                                                options: @pagy_options))
  end

  BATCH_SESSION_KEY = "folio_files_console_batch"

  def add_to_batch
    file_ids = folio_console_records.where(id: params.require(:file_ids)).pluck(:id)

    session[BATCH_SESSION_KEY] ||= {}
    session[BATCH_SESSION_KEY][@klass.to_s] ||= {}
    session[BATCH_SESSION_KEY][@klass.to_s]["file_ids"] ||= []
    session[BATCH_SESSION_KEY][@klass.to_s]["file_ids"] += file_ids
    session[BATCH_SESSION_KEY][@klass.to_s]["file_ids"].uniq!

    render_component_json(Folio::Console::Files::Batch::BarComponent.new(file_klass: @klass))
  end

  def remove_from_batch
    file_ids = folio_console_records.where(id: params.require(:file_ids)).pluck(:id)

    session[BATCH_SESSION_KEY] ||= {}
    session[BATCH_SESSION_KEY][@klass.to_s] ||= {}
    session[BATCH_SESSION_KEY][@klass.to_s]["file_ids"] = (session[BATCH_SESSION_KEY][@klass.to_s]["file_ids"] || []) - file_ids

    render_component_json(Folio::Console::Files::Batch::BarComponent.new(file_klass: @klass))
  end

  def batch_delete
    session_file_ids = session.dig(BATCH_SESSION_KEY, @klass.to_s, "file_ids") || []
    param_file_ids = params.require(:file_ids)

    if param_file_ids.is_a?(Array)
      param_file_ids.map!(&:to_i)
    else
      raise ActionController::BadRequest.new("Invalid file IDs")
    end

    safe_file_ids = param_file_ids & session_file_ids

    if safe_file_ids.size != param_file_ids.size
      raise ActionController::BadRequest.new("Invalid file IDs")
    end

    files = @klass.where(id: safe_file_ids).to_a

    if indestructible_file = files.find { |file| file.indestructible_reason }
      raise ActionController::BadRequest.new(indestructible_file.indestructible_reason)
    end

    if forbidden_file = files.find { |file| !can_now?(:destroy, file) }
      raise ActionController::BadRequest.new("Invalid file IDs - you are not allowed to destroy file #{forbidden_file.id}")
    end

    @klass.transaction do
      files.each { |file| file.destroy! }
    end

    session[BATCH_SESSION_KEY][@klass.to_s]["file_ids"] = []

    render_component_json(Folio::Console::Files::Batch::BarComponent.new(file_klass: @klass),
      flash: { success: t("folio.console.api.file_controller_base.batch_delete_success") })
  end

  private
    def folio_console_collection_includes
      [:tags, :file_placements]
    end

    def filter_params
      params.permit(:by_file_name, :by_placement, :by_tags, :by_used)
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
      ]

      if @klass.new.respond_to?("preview_duration=")
        ary << :preview_duration
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
end
