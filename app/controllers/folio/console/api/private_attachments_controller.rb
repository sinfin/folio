# frozen_string_literal: true

class Folio::Console::Api::PrivateAttachmentsController < Folio::Console::Api::BaseController
  folio_console_controller_for "Folio::PrivateAttachment"

  def create
    @private_attachment = @klass.create!(private_attachment_params)

    # destroy older
    @klass.where(attachmentable: @private_attachment.attachmentable)
          .where.not(id: @private_attachment.id)
          .destroy_all

    render html: cell("folio/console/private_attachments/single_dropzone",
                      @private_attachment.attachmentable,
                      minimal: params[:minimal],
                      name: params[:name],
                      type: params[:type]).show.html_safe
  end

  def destroy
    attachmentable = @private_attachment.attachmentable
    @private_attachment.destroy!

    render html: cell("folio/console/private_attachments/single_dropzone",
                      attachmentable.reload,
                      minimal: params[:minimal],
                      name: params[:name],
                      type: params[:type]).show.html_safe
  end


  private
    def private_attachment_params
      params.require(:private_attachment)
            .permit(:attachmentable_id,
                    :attachmentable_type,
                    :type,
                    :file)
    end
end
