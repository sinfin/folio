# frozen_string_literal: true

namespace :folio_cache do
  task conditional_clear: :environment do
    redis = Redis.new
    my_role = File.read('/var/local/server_name').chomp

    if my_role.present?
      key = "#{Rails.application.class.name}:cache:clear:#{my_role}"
      if redis.get(key).present?
        clear_page_cache!
        redis.del(key)
      end
    end
  end

  def clear_page_cache!
    return unless Rails.application.config.action_controller.perform_caching
    cache_dir = Rails.application.config.action_controller.page_cache_directory
    return if /\/public\Z/.match?(cache_dir.to_s) # do not delete whole /public folder
    return if cache_dir.blank? || !::File.exist?(cache_dir)

    Dir.mktmpdir do |tmp_dir|
      FileUtils.mv cache_dir, tmp_dir
      FileUtils.rmdir tmp_dir
    end
  end
end
