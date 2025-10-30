# frozen_string_literal: true

class Folio::ApplicationJob < ActiveJob::Base
  # Configure sidekiq_options only when Sidekiq is the active queue adapter
  # This prevents errors when using other queue adapters (like :test, :async, etc.)
  def self.adapter_aware_sidekiq_options(**options)
    if Rails.application.config.active_job.queue_adapter.to_s == "sidekiq" && respond_to?(:sidekiq_options)
      Rails.logger.debug "Configuring Sidekiq options for #{name}: #{options}" if Rails.env.development?
      sidekiq_options(options)
    else
      Rails.logger.debug "Skipping Sidekiq options for #{name} (queue adapter: #{Rails.application.config.active_job.queue_adapter}): #{options}" if Rails.env.development?
    end
  end

  private
    def broadcast_file_update(file)
      return if message_bus_user_ids.blank?

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::ApplicationJob/file_update",
                           data: serialized_file(file)[:data],
                         }.to_json,
                         user_ids: message_bus_user_ids
    end

    def message_bus_user_ids
      @message_bus_user_ids ||= Folio::User.where.not(console_url: nil)
                                           .where(console_url_updated_at: 1.hour.ago..)
                                           .pluck(:id)
    end

    def serializer_for(model)
      name = model.class.base_class.name.gsub("Folio::", "")
      serializer = "Folio::Console::#{name}Serializer".safe_constantize
      serializer ||= "#{name}Serializer".safe_constantize
      serializer || Folio::GenericDropzoneSerializer
    end

    def serialized_file(model)
      serializer_for(model).new(model).serializable_hash
    end
end
