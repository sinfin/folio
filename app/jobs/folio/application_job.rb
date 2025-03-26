# frozen_string_literal: true

class Folio::ApplicationJob < ActiveJob::Base
  private
    def broadcast_file_update(file)
      user_ids = Folio::User.where.not(console_url: nil)
                            .where(console_url_updated_at: 1.hour.ago..)
                            .pluck(:id)

      return if user_ids.blank?

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::ApplicationJob/file_update",
                           data: serialized_file(file)[:data],
                         }.to_json,
                         user_ids:
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
