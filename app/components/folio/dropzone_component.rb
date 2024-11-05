# frozen_string_literal: true

class Folio::DropzoneComponent < Folio::ApplicationComponent
  def initialize(records: nil,
                 file_type:,
                 file_human_type:,
                 max_file_size: nil,
                 index_url: nil,
                 destroy_url: nil,
                 prompt: nil,
                 hint: nil,
                 attach_to_document: true,
                 application_namespace: nil,
                 icon: nil)
    @records = records
    @file_type = file_type
    @file_human_type = file_human_type
    @max_file_size = max_file_size
    @prompt = prompt
    @hint = hint
    @destroy_url = destroy_url
    @index_url = index_url
    @attach_to_document = attach_to_document
    @application_namespace = application_namespace
    @icon = icon
  end

  def application_namespace
    @application_namespace.presence || Rails.application.class.name.deconstantize
  end

  def dict
    {
      dictDefaultMessage: @prompt.presence || t(".dictDefaultMessage"),
      dictFallbackMessage: t(".dictFallbackMessage"),
      dictFallbackText: t(".dictFallbackText"),
      dictFileTooBig: t(".dictFileTooBig"),
      dictInvalidFileType: t(".dictInvalidFileType"),
      dictResponseError: t(".dictResponseError"),
      dictCancelUpload: "",
      dictUploadCanceled: t(".dictUploadCanceled"),
      dictCancelUploadConfirmation: t(".dictCancelUploadConfirmation"),
      dictRemoveFile: "",
      dictMaxFilesExceeded: t(".dictMaxFilesExceeded"),
      destroy_failure: t(".destroy_failure"),
      upload_failure: t(".upload_failure"),
    }
  end

  def records_json
    if @records.present?
      @records.map(&:to_h).to_json
    else
      []
    end
  end

  def data
    stimulus_controller("f-dropzone",
                        values: {
                          records: records_json,
                          file_type: @file_type,
                          file_human_type: @file_human_type,
                          max_file_size: @max_file_size,
                          dict: dict.to_json,
                          destroy_url: @destroy_url,
                          index_url: @index_url,
                          persisted_file_count:,
                          pending_file_count: 0,
                          attach_to_document: @attach_to_document,
                        })
  end

  def trigger_button
    klass = "#{application_namespace}::Ui::ButtonComponent".safe_constantize

    if klass
      render(klass.new(tag: :span,
                       label: @prompt.presence || t(".dictDefaultMessage"),
                       variant: :secondary,
                       class_name: "f-dropzone__trigger",
                       data: stimulus_target("trigger"),
                       icon: @icon.present? ? @icon : nil))
    else
      content_tag(:span,
                  @prompt.presence || t(".dictDefaultMessage"),
                  class: "btn btn-secondary f-dropzone__trigger",
                  data: stimulus_target("trigger"))
    end
  end

  def persisted_file_count
    @records.present? ? @records.size : 0
  end
end
