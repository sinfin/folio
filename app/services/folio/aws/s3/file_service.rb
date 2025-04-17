# frozen_string_literal: true

require "open-uri"
require "aws-sdk-s3"

module Folio
  module Aws
    module S3
      class FileService
        attr_reader :bucket

        class << self
          # options:
          #    mfa: "MFA",
          #    version_id: "ObjectVersionId",
          #    request_payer: "requester", # accepts requester
          #    bypass_governance_retention: false,
          #    expected_bucket_owner: "AccountId",
          #    if_match: "IfMatch",
          #    if_match_last_modified_time: Time.now,
          #    if_match_size: 1,
          def delete(key, options = {})
            call(__method__, key, options)
          end

          # options:
          #    mfa: "MFA",
          #    request_payer: "requester", # accepts requester
          #    bypass_governance_retention: false,
          #    expected_bucket_owner: "AccountId",
          #    checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
          def delete_all(prefix, options = {})
            call(__method__, prefix, options)
          end

          # options:
          #    max_attempts: 20 (Integer)
          #    delay: 5 (Float)
          #    before_attempt: (Proc)
          #    before_wait: (Proc)
          def exist?(key, options = {})
            call(__method__, key, options)
          end

          # options:
          #    if_match: "IfMatch",
          #    if_modified_since: Time.now,
          #    if_none_match: "IfNoneMatch",
          #    if_unmodified_since: Time.now,
          #    range: "Range",
          #    response_cache_control: "ResponseCacheControl",
          #    response_content_disposition: "ResponseContentDisposition",
          #    response_content_encoding: "ResponseContentEncoding",
          #    response_content_language: "ResponseContentLanguage",
          #    response_content_type: "ResponseContentType",
          #    response_expires: Time.now,
          #    version_id: "ObjectVersionId",
          #    sse_customer_algorithm: "SSECustomerAlgorithm",
          #    sse_customer_key: "SSECustomerKey",
          #    sse_customer_key_md5: "SSECustomerKeyMD5",
          #    request_payer: "requester", # accepts requester
          #    part_number: 1,
          #    expected_bucket_owner: "AccountId",
          #    checksum_mode: "ENABLED", # accepts ENABLED
          def head(key, options = {})
            call(__method__, key, options)
          end

          # options:
          #    if_match: "IfMatch",
          #    if_modified_since: Time.now,
          #    if_none_match: "IfNoneMatch",
          #    if_unmodified_since: Time.now,
          #    range: "Range",
          #    response_cache_control: "ResponseCacheControl",
          #    response_content_disposition: "ResponseContentDisposition",
          #    response_content_encoding: "ResponseContentEncoding",
          #    response_content_language: "ResponseContentLanguage",
          #    response_content_type: "ResponseContentType",
          #    response_expires: Time.now,
          #    version_id: "ObjectVersionId",
          #    sse_customer_algorithm: "SSECustomerAlgorithm",
          #    sse_customer_key: "SSECustomerKey",
          #    sse_customer_key_md5: "SSECustomerKeyMD5",
          #    request_payer: "requester", # accepts requester
          #    part_number: 1,
          #    expected_bucket_owner: "AccountId",
          #    checksum_mode: "ENABLED", # accepts ENABLED
          def get(key, options = {})
            call(__method__, key, options)
          end

          # options:
          #    if_match: "IfMatch",
          #    if_modified_since: Time.now,
          #    if_none_match: "IfNoneMatch",
          #    if_unmodified_since: Time.now,
          #    range: "Range",
          #    response_cache_control: "ResponseCacheControl",
          #    response_content_disposition: "ResponseContentDisposition",
          #    response_content_encoding: "ResponseContentEncoding",
          #    response_content_language: "ResponseContentLanguage",
          #    response_content_type: "ResponseContentType",
          #    response_expires: Time.now,
          #    version_id: "ObjectVersionId",
          #    sse_customer_algorithm: "SSECustomerAlgorithm",
          #    sse_customer_key: "SSECustomerKey",
          #    sse_customer_key_md5: "SSECustomerKeyMD5",
          #    request_payer: "requester", # accepts requester
          #    part_number: 1,
          #    expected_bucket_owner: "AccountId",
          #    checksum_mode: "ENABLED", # accepts ENABLED
          def read(key, options = {})
            call(__method__, key, options)
          end

          def list_path(prefix)
            call(__method__, prefix)
          end

          # @param [String] key S3 file path
          # @param [String|File] source Use URI or File
          # @param [Hash] options
          #
          # URI options:
          #     multipart_threshold: 104857600 (Integer) Files larger than or equal to `:multipart_threshold` are
          #                                              uploaded using the S3 multipart APIs. Default threshold is
          #                                              100MB.
          #     thread_count: 10 (Integer) The number of parallel multipart uploads. This option is not used if the file
          #                                is smaller than `:multipart_threshold`.
          #     progress_callback (Proc) A Proc that will be called when each chunk of the upload is sent. It will be
          #                              invoked with [bytes_read], [total_sizes]
          #
          # File options:
          #    acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read,
          #                      bucket-owner-read, bucket-owner-full-control
          #    body: source_file,
          #    cache_control: "CacheControl",
          #    content_disposition: "ContentDisposition",
          #    content_encoding: "ContentEncoding",
          #    content_language: "ContentLanguage",
          #    content_length: 1,
          #    content_md5: "ContentMD5",
          #    content_type: "ContentType",
          #    checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
          #    checksum_crc32: "ChecksumCRC32",
          #    checksum_crc32c: "ChecksumCRC32C",
          #    checksum_crc64nvme: "ChecksumCRC64NVME",
          #    checksum_sha1: "ChecksumSHA1",
          #    checksum_sha256: "ChecksumSHA256",
          #    expires: Time.now,
          #    if_match: "IfMatch",
          #    if_none_match: "IfNoneMatch",
          #    grant_full_control: "GrantFullControl",
          #    grant_read: "GrantRead",
          #    grant_read_acp: "GrantReadACP",
          #    grant_write_acp: "GrantWriteACP",
          #    write_offset_bytes: 1,
          #    metadata: {
          #      "MetadataKey" => "MetadataValue",
          #    },
          #    server_side_encryption: "AES256", # accepts AES256, aws:kms, aws:kms:dsse
          #    storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA,
          #                                 INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW,
          #                                 EXPRESS_ONEZONE
          #    website_redirect_location: "WebsiteRedirectLocation",
          #    sse_customer_algorithm: "SSECustomerAlgorithm",
          #    sse_customer_key: "SSECustomerKey",
          #    sse_customer_key_md5: "SSECustomerKeyMD5",
          #    ssekms_key_id: "SSEKMSKeyId",
          #    ssekms_encryption_context: "SSEKMSEncryptionContext",
          #    bucket_key_enabled: false,
          #    request_payer: "requester", # accepts requester
          #    tagging: "TaggingHeader",
          #    object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
          #    object_lock_retain_until_date: Time.now,
          #    object_lock_legal_hold_status: "ON", # accepts ON, OFF
          #    expected_bucket_owner: "AccountId",
          def upload(key, source, options = {})
            call(__method__, key, source, options)
          end

          private
            def call(method, *attrs)
              new.send(method, *attrs)
            end
        end

        def initialize
          # Credentials are loaded from /config/initializers/aws_sdk.rb
          @s3 = ::Aws::S3::Resource.new
          @bucket = @s3.bucket(ENV.fetch("S3_BUCKET_NAME"))
        end

        def delete(key, options = {})
          bucket.object(key).delete(options)
        rescue ::Aws::S3::Errors::NoSuchKey
          raise
        rescue ::Aws::S3::Errors::ServiceError
          raise
        end

        def delete_all(prefix, options = {})
          bucket.objects(prefix: prefix).batch_delete!(options)
        rescue ::Aws::S3::Errors::NoSuchKey
          raise
        rescue ::Aws::S3::Errors::ServiceError
          raise
        end

        def exist?(key, options = {})
          bucket.object(key).exists?(options)
        rescue ::Aws::S3::Errors::ServiceError
          raise
        end

        def head(key, options = {})
          bucket.object(key).head(options)
        rescue ::Aws::S3::Errors::NoSuchKey
          raise
        rescue ::Aws::S3::Errors::ServiceError
          raise
        end

        def read(key, options = {})
          get(key, options).body.read
        end

        def get(key, options = {})
          bucket.object(key).get(options)
        rescue ::Aws::S3::Errors::NoSuchKey
          raise
        rescue ::Aws::S3::Errors::ServiceError
          raise
        end

        def list_path(prefix)
          bucket.objects(prefix: prefix).map(&:key)
        rescue ::Aws::S3::Errors::ServiceError
          raise
        end

        def upload(key, source, options = {})
          obj = bucket.object(key)

          case source
          when String
            URI.open(source) do |file|
              obj.put(options.merge(body: file.read))
            end
          when File
            obj.upload_file(source.path, options)
          else
            raise ArgumentError, "Unknown source: #{source.class}"
          end
        rescue ::Aws::S3::Errors::ServiceError
          raise
        rescue OpenURI::HTTPError
          raise
        rescue StandardError
          raise
        end
      end
    end
  end
end
