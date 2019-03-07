# frozen_string_literal: true

module Folio::Console::DefaultActions
  extend ActiveSupport::Concern

  def create
    instance_variable_set(folio_console_record_variable_name,
                          @klass.create(folio_console_params))
    respond_with folio_console_record
  end

  def update
    folio_console_record.update(folio_console_params)
    respond_with folio_console_record
  end

  def destroy
    folio_console_record.destroy
    respond_with folio_console_record
  end

  def event
    event = params.require(:aasm_event).to_sym

    if folio_console_record.aasm
                           .events(possible: true)
                           .any? { |e| e.name == event }
      folio_console_record.send("#{event}!")
      respond_with folio_console_record
    else
      human_event = AASM::Localizer.new.human_event_name(@klass, event)

      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { error: I18n.t('folio.console.base_controller.invalid_event', event: human_event) }
    end
  end

  private

    def folio_console_name_base
      params[:controller].split('/').last.singularize
    end

    def folio_console_record_variable_name
      "@#{folio_console_name_base}".to_sym
    end

    def folio_console_record
      instance_variable_get(folio_console_record_variable_name)
    end

    def folio_console_params
      send("#{folio_console_name_base}_params")
    end
end
