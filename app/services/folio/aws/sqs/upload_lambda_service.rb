# frozen_string_literal: true

module Folio
  module Aws
    module Sqs
      class UploadLambdaService < Folio::Aws::Sqs::BaseMessageProducerService
        class << self
          def reprocess_metadata(full_s3_path)
            new.reprocess_metadata(full_s3_path)
          end
        end

        def initialize
          super(ENV.fetch("AWS_UPLOAD_LAMBDA_QUEUE"))
        end

        # Example of S3 event notification sent from AWS
        # {
        #   "Records": [
        #     { "eventVersion": "2.1",
        #       "eventSource": "aws:s3",
        #       "awsRegion": "eu-west-1",
        #       "eventTime": "2025-05-12T10:18:26.262Z",
        #       "eventName": "ObjectCreated:Put",
        #       "userIdentity": { "principalId": "AWS:AROATJHQDXDY37SRKFA54:jan.zlamal" },
        #       "requestParameters": { "sourceIPAddress": "193.179.119.129" },
        #       "responseElements": {
        #         "x-amz-request-id": "THSNWR3S899Q3KYF",
        #         "x-amz-id-2": "YkkYk6ZwGYQdYrlYVwy8AM9coqPUMaWBTfoR5r2eNIJ1uPkcOiHVnUeZC+r4TsyJrHYL4TtanCp2bnIiCn1QZGG0C3Low/6s"
        #       },
        #       "s3": {
        #         "s3SchemaVersion": "1.0",
        #         "configurationId": "tf-s3-topic-20250508180827896900000002",
        #         "bucket": {
        #           "name": "hosting-prodsinfin-folio-demo",
        #           "ownerIdentity": {
        #             "principalId": "AT19ZBIQ1865M"
        #           },
        #           "arn": "arn:aws:s3:::hosting-prodsinfin-folio-demo"
        #         },
        #         "object": {
        #           "key": "uploads/2025/05/12/folio-file-image/276c7637-4f34-436e-810b-4fed5f55b170/file",
        #           "size": 451740,
        #           "eTag": "a9b2cca842fc390d67d0a19f4f4590b1",
        #           "sequencer": "006821CAF22E3A3256"
        #         }
        #       }
        #     }
        #   ]
        # }
        def reprocess_metadata(full_s3_path)
          # Bellow is required minimum by our upload lambda to successfully trigger creation of new metadata.json
          # lambda code: /aws/lambdas/upload/index.js
          send_message(
            {
              Records: [
                {
                  s3: {
                    bucket: { name: ENV.fetch("S3_BUCKET_NAME") },
                    object: { key: full_s3_path }
                  }
                }
              ]
            }
          )
        end
      end
    end
  end
end
