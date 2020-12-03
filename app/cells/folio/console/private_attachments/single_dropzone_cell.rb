# frozen_string_literal: true

class Folio::Console::PrivateAttachments::SingleDropzoneCell < Folio::ConsoleCell
  class_name "f-c-private-attachments-single-dropzone", :minimal

  def show
    render if model.present? && name.present? && type.present?
  end

  def name
    @name ||= options[:name]
  end

  def type
    @type ||= options[:type]
  end

  def attachment
    @attachment ||= model.send(name)
  end

  def upload_data
    p = {
      "private_attachment[attachmentable_id]" => model.id,
      "private_attachment[attachmentable_type]" => model.class.base_class.to_s,
      "private_attachment[type]" => type,
    }

    p["minimal"] = 1 if options[:minimal]
    p["name"] = options[:name]
    p["type"] = options[:type]

    {
      url: url_for([:console, :api, Folio::PrivateAttachment]),
      paramname: "private_attachment[file]",
      params: p.to_json
    }
  end

  def destroy_data
    p = {
      minimal: options[:minimal] ? 1 : nil,
      name: options[:name],
      type: options[:type],
    }

    {
      url: url_for([:console, :api, attachment, p]),
      "destroy-confirm" => t("folio.console.confirmation")
    }
  end

  def href
    attachment.file.remote_url(expires: 1.hour.from_now)
  end
end
