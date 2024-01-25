# frozen_string_literal: true

class Folio::Console::PrivateAttachmentsFieldsComponent < Folio::Console::ApplicationComponent
  def initialize(f:, key: :private_attachments, single: false)
    @f = f
    @key = key
    @single = single

    @file_type = if @f.object.class.reflections[key.to_s]
      @f.object.class.reflections[key.to_s].options[:class_name]
    else
      "Folio::PrivateAttachment"
    end

    @file_klass = @file_type.constantize

    @attachments = @f.object.send(@key)
  end

  def data
    stimulus_controller("f-c-private-attachments-fields")
  end

  def add_button
    cell("folio/console/ui/button",
         variant: :success,
         icon: :plus,
         label: t("folio.console.actions.add"))
  end

  def loader_data
    serializer = Folio::Console::PrivateAttachmentSerializer

    attachments_json = @attachments.map do |attachment|
      serializer.new(attachment).serializable_hash[:data]
    end.to_json

    stimulus_target("loader").merge(attachments: attachments_json)
  end
end
