# frozen_string_literal: true

require "aws-sdk-sqs"

module Folio
  module Aws
    module Sqs
      class BaseMessageProducerService
        class << self
          def send_message(queue_name, message_body, attributes: {})
            new(queue_name).send_message(message_body, attributes: attributes)
          end
        end

        def initialize(queue_name)
          # Credentials are loaded from /config/initializers/aws_sdk.rb
          @client = ::Aws::SQS::Client.new
          @queue_url = queue_url(queue_name)
        end

        def send_message(message_body, attributes: {})
          body = message_body.is_a?(Hash) ? message_body.to_json : message_body.to_s

          @client.send_message(
            queue_url: @queue_url,
            message_body: body,
            message_attributes: prepare_sqs_attributes(attributes)
          )
        rescue Aws::SQS::Errors::ServiceError => e
          Rails.logger.error "SQS Send Error for queue '#{@queue_url}': #{e.message}"
          raise
        rescue StandardError => e
          Rails.logger.error "Unexpected error sending SQS message for queue '#{@queue_url}': #{e.message}"
          raise
        end

        private
          def prepare_sqs_attributes(attributes_hash)
            return {} if attributes_hash.blank?

            attributes_hash.transform_values do |value|
              { string_value: value.to_s, data_type: "String" }
            end
          end

          def queue_url(queue_name)
            "#{@client.config.endpoint}/#{::Aws.config[:credentials].account_id}/#{queue_name}"
          end
      end
    end
  end
end
