# frozen_string_literal: true

class Folio::Console::Ui::StiBadgeComponent < Folio::Console::ApplicationComponent
  def initialize(record:)
    @record = record
  end

  def icon
    if model_class.respond_to?(:klasses_for_console)
      model_class.klasses_for_console[model_class]
    end
  end

  def model_class
    @model_class ||= if @record.new_record? && @record.try(:type)
      @record.type.constantize
    else
      @record.class
    end
  end
end
