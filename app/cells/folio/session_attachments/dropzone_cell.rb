# frozen_string_literal: true

class Folio::SessionAttachments::DropzoneCell < Folio::ApplicationCell
  def dropzone_model
    {
      create_url: create_url,
      destroy_url: destroy_url,
      records: model.unpaired.where(web_session_id: session.id.public_id),
      param_name: "folio_session_attachment[file]",
      create_thumbnails: model < Folio::SessionAttachment::Image,
      file_formats: file_formats,
      max_file_size: 20,
    }
  end

  def create_url
    controller.folio.folio_session_attachments_path(type: model.to_s)
  end

  def destroy_url
    controller.folio.folio_session_attachment_path(id: "ID", type: model.to_s)
  end

  def file_formats
    if defined?(model::ALLOWED_FORMATS)
      model::ALLOWED_FORMATS
    end
  end
end
