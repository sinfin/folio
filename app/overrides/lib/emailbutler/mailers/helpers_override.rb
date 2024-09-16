# frozen_string_literal: true

Emailbutler::Mailers::Helpers.module_eval do
  private
    def save_emailbutler_message
      message.message_id = @emailbutler_message.uuid
      Emailbutler.set_message_attribute(@emailbutler_message, :send_to, message.to)
      Emailbutler.set_message_attribute(@emailbutler_message, :subject, message.subject)
      Emailbutler.set_message_attribute(@emailbutler_message, :site_id, site.id)
      Emailbutler.save_message(@emailbutler_message)
    end
end
