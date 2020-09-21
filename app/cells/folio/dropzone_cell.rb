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
      "prompt" => prompt,
      "param-name" => param_name,
      "file-formats" => file_formats,
      "records" => records,
      "destroy-failure" => destroy_failure,
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
      model[:file_formats].map { |ff| "image/#{ff}" }.join(", ")
    else
      nil
    end
  end

  def prompt
    model[:prompt].presence || t(".prompt")
  end

  def destroy_failure
    model[:destroy_failure].presence || t(".destroy_failure")
  end

  def param_name
    model[:param_name] || "file"
  end
end
