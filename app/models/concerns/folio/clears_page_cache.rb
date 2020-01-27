# frozen_string_literal: true

module Folio::ClearsPageCache
  extend ActiveSupport::Concern

  included do
    after_commit :clear_page_cache!
    after_touch :clear_page_cache!
  end

  module ClassMethods
    # overridable
    def clears_page_cache_on_save?
      true
    end
  end

  private

    def clear_page_cache!
      return unless self.class.clears_page_cache_on_save?
      return unless Rails.application.config.action_controller.perform_caching
      cache_dir = Rails.application.config.action_controller.page_cache_directory
      return if cache_dir.to_s =~ /\/public\Z/ # do not delete whole /public folder
      return if cache_dir.blank?

      send_clear_page_cache_signal!

      return if !::File.exist?(cache_dir)

      tmp_dir = Dir.mktmpdir
      begin
        FileUtils.mv cache_dir, tmp_dir
      ensure
        FileUtils.remove_entry tmp_dir
      end
    end

    def send_clear_page_cache_signal!
      server_names = Rails.application.config.folio_server_names
      return if server_names.blank?

      redis = Redis.new
      my_role = File.read('/var/local/server_name').chomp

      return if my_role.blank?
      (server_names - [my_role]).each do |role|
        redis.set("#{Rails.application.class.name}:cache:clear:#{role}", 1)
      end
    rescue Errno::ENOENT
    end
end
