# frozen_string_literal: true

require "jwt"

module Folio
  module Aws
    class FileJwt
      class << self
        # Decode JWT and returns payload. Currently not used anywhere in BE!
        #
        # @param [String] jwt_token
        #
        # @return [Hash] JWT payload
        def decode(jwt_token)
          JWT.decode(jwt_token, ENV.fetch("AWS_JWT_FILE_PROCESSING_SECRET"), true, { algorithm: "HS256" }).first
        end

        # Encode payload and return JWT token
        #
        # @param [Hash] payload
        #
        # @return [String] JWT token
        def encode(payload)
          JWT.encode(payload, ENV.fetch("AWS_JWT_FILE_PROCESSING_SECRET"), "HS256")
        end

        # Get class from class name in string. Return class only if it is one of the file class
        #
        # @param [String] class_name class name. (e.g. Folio::File::Image or Folio::SessionAttachment::Document)
        #
        # @return [Class,nil] child of class that cares about file, otherwise nil
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
