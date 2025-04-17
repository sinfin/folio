# frozen_string_literal: true

class S3FileService
  attr_reader :bucket

  def initialize
    @s3 = Aws::S3::Resource.new(
      region: ENV.fetch("S3_REGION"),
      access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
    )
    @bucket = @s3.bucket(ENV.fetch("S3_BUCKET"))
  end

  def delete(key)
    obj = bucket.object(key)
    obj.delete
  rescue Aws::S3::Errors::NoSuchKey
    # TODO: error handling
    raise
  rescue Aws::S3::Errors::ServiceError
    # TODO: error handling
    raise
  end

  def read(key)
    obj = bucket.object(key)
    obj.get.body.read
  rescue Aws::S3::Errors::NoSuchKey
    # TODO: error handling
    raise
  rescue Aws::S3::Errors::ServiceError
    # TODO: error handling
    raise
  end

  def list_path(prefix)
    bucket.objects(prefix: prefix).map(&:key)
  rescue Aws::S3::Errors::ServiceError
    # TODO: error handling
    raise
  end
end