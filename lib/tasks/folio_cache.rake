# frozen_string_literal: true

namespace :folio_cache do
  task conditional_clear: :environment do
    pid_file_path = Rails.root.join('tmp', 'folio_cache_conditional_clear.pid')

    if File.exist?(pid_file_path)
      Rails.logger.warn 'PID file already exists for folio_cache:conditional_clear'
      exit 1
    else
      begin
        File.open(pid_file_path, 'w') { |f| f << Process.pid }
        Rails.logger.info 'Starting folio_cache:conditional_clear'

        redis = Redis.new
        my_role = File.read('/var/local/server_name').chomp

        if my_role.present?
          key = "#{Rails.application.class.name}:cache:clear:#{my_role}"
          if redis.get(key).present?
            Rails.logger.info 'Clearing cache via folio_cache:conditional_clear'
            clear_page_cache!
            redis.del(key)
          else
            Rails.logger.info 'Nothing to clear via folio_cache:conditional_clear'
          end
        end
      ensure
        File.delete(pid_file_path)
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
