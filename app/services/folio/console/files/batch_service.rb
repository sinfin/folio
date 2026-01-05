# frozen_string_literal: true

# Handles batch operations for files in the console interface using Redis for state management.
#
# This service uses an instance-based approach for better performance and cleaner API.
# The session_id and file_class_name are passed to the constructor, and then all methods
# use simple arguments without repetitive parameters.
#
# Example usage:
#   batch_service = Folio::Console::Files::BatchService.new(
#     session_id: "session_123",
#     file_class_name: "Folio::File::Image"
#   )
#   batch_service.add_file(1)
#   batch_service.add_file(2)
#   batch_service.set_form_open(true)
#   file_ids = batch_service.get_file_ids
#   batch_service.clear_files
#
class Folio::Console::Files::BatchService
  REDIS_NAMESPACE = "folio:console:files:batch"
  DEFAULT_EXPIRATION = 1.hour.to_i

  def initialize(session_id:, file_class_name:)
    @session_id = session_id
    @file_class_name = file_class_name
  end

  # File operations
  def add_file(file_id)
    redis_client.sadd(files_key, file_id)
    redis_client.expire(files_key, DEFAULT_EXPIRATION)

    file_id
  end

  def add_files(file_ids)
    return [] if file_ids.empty?

    redis_client.sadd(files_key, file_ids)
    redis_client.expire(files_key, DEFAULT_EXPIRATION)

    file_ids
  end

  def remove_files(file_ids)
    return [] if file_ids.empty?

    redis_client.srem(files_key, file_ids)

    file_ids
  end

  def get_file_ids
    redis_client.smembers(files_key).map(&:to_i)
  end

  def file_count
    redis_client.scard(files_key)
  end

  def clear_files
    redis_client.del(files_key)
  end

  def has_file?(file_id)
    redis_client.sismember(files_key, file_id)
  end

  # Form state operations
  def set_form_open(open = true)
    form_key
    if open
      redis_client.set(form_key, "true", ex: DEFAULT_EXPIRATION)
    else
      redis_client.del(form_key)
    end
  end

  def form_open?
    redis_client.get(form_key) == "true"
  end

  # Download state operations
  def set_download_status(status_hash)
    if status_hash.nil?
      redis_client.del(download_key)
    else
      redis_client.set(download_key, status_hash.to_json, ex: DEFAULT_EXPIRATION)
    end
  end

  def get_download_status
    status_json = redis_client.get(download_key)
    status_json ? JSON.parse(status_json) : nil
  end

  # Batch queue operations (for handle_batch_queue method)
  def handle_queue(add_ids, remove_ids, valid_ids)
    # Use Redis transaction for atomicity
    redis_client.multi do |redis|
      # Only add IDs that are in the valid_ids list
      valid_add_ids = add_ids & valid_ids
      redis.sadd(files_key, valid_add_ids) if valid_add_ids.any?

      # Remove specified IDs
      redis.srem(files_key, remove_ids) if remove_ids.any?

      # Set expiration
      redis.expire(files_key, DEFAULT_EXPIRATION)
    end

    # Return current file IDs
    get_file_ids
  end

  private
    def files_key
      @files_key ||= "#{REDIS_NAMESPACE}:files:#{@session_id}:#{@file_class_name}"
    end

    def form_key
      @form_key ||= "#{REDIS_NAMESPACE}:form:#{@session_id}:#{@file_class_name}"
    end

    def download_key
      @download_key ||= "#{REDIS_NAMESPACE}:download:#{@session_id}:#{@file_class_name}"
    end

    def redis_client
      @redis_client ||= Redis.new(
        url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
        timeout: ENV.fetch("REDIS_TIMEOUT", 5).to_i,
        reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 3).to_i,
        reconnect_delay: ENV.fetch("REDIS_RECONNECT_DELAY", 0.5).to_f,
        reconnect_delay_max: ENV.fetch("REDIS_RECONNECT_DELAY_MAX", 5.0).to_f,
      )
    end
end
