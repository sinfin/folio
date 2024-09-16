# frozen_string_literal: true

Emailbutler::WebhooksController.class_eval do
  before_action :verify_signature

  private
    def verify_signature
      if signature = request.headers["X-Twilio-Email-Event-Webhook-Signature"]
        timestamp = request.headers["X-Twilio-Email-Event-Webhook-Timestamp"]
        public_key = OpenSSL::PKey::EC.new(Base64.decode64(ENV.fetch("SENDGRID_WEBHOOK_PUBLIC_KEY")))
        timestamped_playload = "#{timestamp}#{request.body.read}"
        payload_digest = Digest::SHA256.digest(timestamped_playload)
        decoded_signature = Base64.decode64(signature)

        begin
          public_key.dsa_verify_asn1(payload_digest, decoded_signature)
        rescue
          head :unauthorized
        end
      end
    end

    def sendgrid_params
      p = params.permit("_json" => %w[smtp-id event timestamp sg_message_id])

      if p[:_json].present?
        p[:_json].map! { |h| h["smtp-id"].delete!("<>"); h.to_h }
      end

      p
    end
end
