# frozen_string_literal: true

module Folio
  module Aws
    class FileJwt
      class << self
        def decode(jwt_token)
          JWT.decode(jwt_token, ENV.fetch("AWS_JWT_FILE_PROCESSING_SECRET"), true, { algorithm: "HS384" }).first
        end

        def encode(payload)
          JWT.encode(payload, ENV.fetch("AWS_JWT_FILE_PROCESSING_SECRET"), "HS384")
        end

        def file_subclass(class_name)
          return nil unless class_name

          @file_classes ||= Rails.application.config.folio_direct_s3_upload_class_names.map(&:safe_constantize)

          subclass = class_name.safe_constantize
          @file_classes.any? { |super_class| subclass < super_class } ? subclass : nil
        rescue NameError
          nil
        end
      end
    end
  end
end
