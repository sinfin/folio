# frozen_string_literal: true

module Folio
  module Aws
    module Sqs
      class ProcessingLambdaService < Folio::Aws::Sqs::BaseMessageProducerService
        class << self
          def process_s3_file(full_s3_path, mime_type, custom_options = {}, attributes = {})
            new.process_s3_file(full_s3_path, mime_type, custom_options, attributes)
          end
        end

        def initialize
          super(ENV.fetch("AWS_PROCESSING_LAMBDA_QUEUE"))
        end

        def process_s3_file(full_s3_path, mime_type, custom_options = {}, attributes = {})
          send_message(
            {
              s3_path: full_s3_path,
              mime_type: mime_type,
              options: custom_options
            },
            attributes: attributes
          )
        end
      end
    end
  end
end
