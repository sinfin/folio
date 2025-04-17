# frozen_string_literal: true

module Folio
  module Aws
    class FileJwt
      class Payload

        # Mapping from JWT payload keys to actual names to make JWT shorter
        MAPPINGS = {
          # File unique ID
          file_id: :fid,
          # Class name for verification if content matches the class
          class_name: :cn,
          # File version
          version: :v,
          # Path where we want to store the image after processing
          s3_path: :s3,
          # Endpoint for notification that metadata are generated. Nil means you'll never be notified and if you lost
          # s3_path you won't have reference to file or metadata. It left orphans there!
          metadata_endpoint: :me,
          # If we want to skip rekognition for this file
          skip_rekognition: :sr,
          # If available we will verify if cookie session id belongs to this user
          user_session_id: :sid
        }

        def initialize(data)
          # Verify if options does not have some unknown attributes.
          unknown_keys = data.keys - MAPPINGS.keys

          raise StandardError, "Unknown keys #{unknown_keys.join(", ")}" unless unknown_keys.blank?

          @data = data
        end

        # Set key into data if exists
        def []=(key, value)

          raise StandardError, "Unknown key #{key}" unless MAPPINGS.key?(key)

          @data[key] = value
        end

        # This is called in case if method not exists in class and we will use method name as attribute if it is know.
        # You can call easily for example
        #    Folio::Aws::FileJwt::Payload.new(file_id: 1).file_id
        def method_missing(method, *args, &blk)
          return @data[method] if MAPPINGS.key?(method)

          super
        end

        # Returns payload for JWT encoding
        def to_payload
          @data.each_with_object({}) do |(key, value), hash|
            hash[MAPPINGS[key]] = value if value
          end
        end

        # Returns data as Hash
        def to_h
          @data.clone
        end

        class << self
          # Creates Payload object from JWT payload
          def from_payload(payload)
            # Verify if payload does not have some unknown attributes.
            unknown_keys = payload.keys - MAPPINGS.values

            raise StandardError, "Unknown keys #{unknown_keys.join(", ")}" unless unknown_keys.blank?

            data = MAPPINGS.each_with_object({}) do |(key, value), hash|
              v = payload[value]
              hash[key] = v if v
            end

            new(data)
          end
        end
      end
    end
  end
end
