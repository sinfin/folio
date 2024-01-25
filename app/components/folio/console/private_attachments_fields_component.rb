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

    @attachments = []
    @marked_for_destruction = []

    @f.object.send(@key).each do |attachment|
      if attachment.marked_for_destruction?
        @marked_for_destruction << attachment
      else
        @attachments << attachment
      end
    end
  end

  def data
    stimulus_controller("f-c-private-attachments-fields",
                        values: {
                          file_type: @file_type,
                          file_human_type: @file_klass.human_type,
                          base_key:,
                          single: @single,
                        })
  end

  def base_key
    @base_key ||= begin
      str = @f.lookup_model_names[0]

      @f.lookup_model_names[1..].each do |lookup_key|
        str += "[#{lookup_key}]"
      end

      "#{str}[#{@key}_attributes]"
    end
  end

  def add_button
    cell("folio/console/ui/button",
         variant: :success,
         icon: :plus,
         label: t("folio.console.actions.add"),
         data: stimulus_target("addButton"),
         dropzone: true)
  end

  def loader_data
    serializer = Folio::Console::PrivateAttachmentSerializer

    attachments_json = @attachments.map do |attachment|
      serializer.new(attachment).serializable_hash[:data]
    end.to_json

    stimulus_target("loader").merge(attachments: attachments_json)
  end

  def input_data(key)
    if key == :position
      stimulus_target("positionInput")
    end
  end
end
