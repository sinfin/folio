# frozen_string_literal: true

class Folio::DropzoneCell < Folio::ApplicationCell
  def show
    render if model.present? && model[:create_url] && model[:destroy_url]
  end

  def data
    {
      "index-url" => model[:index_url],
      "create-url" => model[:create_url],
      "destroy-url" => model[:destroy_url],
      "create-thumbnails" => model[:create_thumbnails] ? "true" : nil,
      "param-name" => param_name,
      "file-formats" => file_formats,
      "file-type" => model[:file_type] || "Folio::File::Document",
      "file-human-type" => model[:file_type].try(:constantize).try(:human_type) || "document",
      "records" => records,
      "destroy-failure" => destroy_failure,
      "max-files" => model[:max_files],
      "max-file-size" => model[:max_file_size],
      "dict" => dict.to_json,
    }
  end

  def records
    if model[:records]
      model[:records].map(&:to_h).to_json
    else
      nil
    end
  end

  def file_formats
    if model[:file_formats]
      model[:file_formats].map do |ff|
        if ff.include?("/")
          ff
        else
          "image/#{ff}"
        end
      end.join(", ")
    else
      nil
    end
  end

  def destroy_failure
    model[:destroy_failure].presence || t(".destroy_failure")
  end

  def param_name
    model[:param_name] || "file"
  end

  def dict
    {
      dictDefaultMessage: model[:prompt].presence || t(".dictDefaultMessage"),
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
    }
  end
end
