# frozen_string_literal: true

class Folio::Console::Files::Batch::BarComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:, change_to_propagate: nil, multi_picker: false)
    @file_klass = file_klass
    @change_to_propagate = change_to_propagate
    @multi_picker = multi_picker
  end

  def data
    stimulus_controller("f-c-files-batch-bar",
                        values: {
                          base_api_url: url_for([:console, :api, @file_klass]),
                          status: "loaded",
                          file_ids_json: file_ids.to_json,
                          change_to_propagate: (@change_to_propagate || {}).to_json,
                          multi_picker: @multi_picker,
                        },
                        action: {
                          "f-c-files-batch-bar:action" => "batchActionFromFile",
                          "f-c-files-batch-bar:reload" => "onReloadTrigger",
                          "f-c-files-batch-bar:message" => "onMessage",
                          "f-c-files-batch-form:submit" => "submitForm",
                          "f-c-files-batch-form:cancel" => "cancelForm",
                          "f-file-list-file:reloadForm" => "reloadForm",
                        }).merge(serialized_files: serialized_files_json)
  end

  def file_ids
    @file_ids ||= batch_service.get_file_ids
  end

  def form_open
    @form_open ||= batch_service.form_open?
  end

  def files_ary
    @files_ary ||= file_ids.present? ? @file_klass.where(id: file_ids).to_a : []
  end

  def buttons_data
    return [] if files_ary.blank?

    ary = []

    if files_ary.all? { |file| can_now?(:destroy, file) }
      indestructible_file = files_ary.find { |file| file.indestructible_reason }

      base = { variant: :danger, icon: :delete, label: t(".delete") }

      if indestructible_file.present?
        base[:disabled] = true
        ary << [stimulus_tooltip(indestructible_file.indestructible_reason), base]
      else
        base[:data] = stimulus_action("delete")
        ary << [nil, base]
      end
    end

    if download_hash
      if download_hash["url"]
        ary << [nil, {
          variant: :success,
          icon: :download,
          label: t(".download"),
          href: download_hash["url"],
          target: "_blank",
        }]
      else
        ary << [nil, {
          variant: :medium_dark,
          icon: :download,
          label: t(".download"),
          disabled: true,
        }]
      end
    else
      ary << [nil, {
        variant: :medium_dark,
        icon: :download,
        label: t(".download"),
        data: stimulus_action("download")
      }]
    end

    if files_ary.all? { |file| can_now?(:update, file) }
      ary << [nil, {
        variant: :medium_dark,
        icon: :menu,
        label: t(".settings"),
        data: stimulus_action("openForm")
      }]
    end

    ary << [{ add_to_picker: "true" }, {
      variant: :success,
      icon: :arrow_up,
      label: t(".add_to_picker/#{@file_klass.human_type}", default: t(".add_to_picker/default")),
      data: stimulus_action("addToPicker"),
    }]

    ary
  end

  def download_hash
    return @download_hash unless @download_hash.nil?

    @download_hash = begin
      h = batch_service.get_download_status

      if h && h["timestamp"] && h["timestamp"] >= Folio::File::BatchDownloadJob::S3_FILE_LIFESPAN.ago.to_i
        h
      else
        false
      end
    end
  end

  private
    def session_id
      session.id.public_id
    end

    def file_class_name
      @file_klass.to_s
    end

    def batch_service
      @batch_service ||= Folio::Console::Files::BatchService.new(session_id: session_id, file_class_name: file_class_name)
    end

    def serialized_files_json
      if @multi_picker
        Folio::Console::FileSerializer.new(files_ary)
                                      .serializable_hash[:data]
                                      .to_json
      end
    end
end
