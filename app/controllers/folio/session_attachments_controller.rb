# frozen_string_literal: true

require_dependency "folio/application_controller"

class Folio::SessionAttachmentsController < Folio::ApplicationController
  before_action :init_session_if_needed

  def create
    attachment = klass.new(attachment_params)

    attachment.web_session_id = session.id.public_id
    attachment.save!

    render json: attachment.to_h
  end

  def destroy
    attachment = klass.where(web_session_id: session.id.public_id)
                      .friendly
                      .find(params[:id])

    attachment.destroy!

    head 200
  end

  def index
    render json: klass.unpaired
                      .where(web_session_id: session.id.public_id)
                      .map(&:to_h)
  end

  private
    def attachment_params
      params.require(:folio_session_attachment)
            .permit(:file)
    end

    def klass
      type = params.require(:type)

      if Folio::SessionAttachment::Base.valid_types.map(&:to_s).include?(type)
        type.constantize
      else
        raise ActionController::ParameterMissing, :type
      end
    end

    def init_session_if_needed
      session[:init] = 1 if session.id.nil?
    end
end
