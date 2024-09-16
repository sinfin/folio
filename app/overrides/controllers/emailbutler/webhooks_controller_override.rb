# frozen_string_literal: true

Emailbutler::WebhooksController.class_eval do
  before_action :verify_signature

  private
    def verify_signature
      head :unauthorized unless ENV["SMTP_WEBHOOK_SIGNATURE"] == request.headers["x-twilio-email-event-webhook-signature"]
    end

    def sendgrid_params
      p = params.permit("_json" => %w[smtp-id event timestamp sg_message_id])
      p[:_json].map! { |h| h["smtp-id"].delete!("<>"); h.to_h }
      p
    end
end
