# frozen_string_literal: true

require "aws-sdk-core"

credentials = [
  ENV.fetch("AWS_ACCESS_KEY_ID"),
  ENV.fetch("AWS_SECRET_ACCESS_KEY"),
  # TODO: this is optional and it's not defined in .env.example! Is it present in production or not? If not, how we
  #       obtain this?
  ENV.fetch("AWS_SESSION_TOKEN"),
]

sts_client = ::Aws::STS::Client.new(
  region: ENV.fetch("S3_REGION"),
  credentials: Aws::Credentials.new(*credentials)
)

# Default configuration for all aws SDK connections
Aws.config.update(
  region: ENV.fetch("S3_REGION"),
  credentials: Aws::Credentials.new(
    *credentials,
    # Set Account ID by default
    # TODO: Will this potentially break something? I presume it can't change over time. So it should be ok. Currently
    #       used only for SQS url: app/services/folio/aws/sqs/base_message_producer_service.rb
    account_id: sts_client.get_caller_identity.account
  )
)
