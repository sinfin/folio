# frozen_string_literal: true

module Folio::Console::DefaultActions
  extend ActiveSupport::Concern

  def index
    if folio_console_records.respond_to?(:ordered)
      records = folio_console_records.ordered
    else
      records = folio_console_records
    end

    pagy, records = pagy(records)
    instance_variable_set('@pagy', pagy)
    instance_variable_set(folio_console_record_variable_name(plural: true),
                          records)
  end

  def create
    instance_variable_set(folio_console_record_variable_name,
                          @klass.create(folio_console_params))
    respond_with folio_console_record, location: respond_with_location
  end

  def update
    folio_console_record.update(folio_console_params)
    respond_with folio_console_record, location: respond_with_location
  end

  def destroy
    folio_console_record.destroy
    respond_with folio_console_record, location: respond_with_location
  end

  def event
    event = params.require(:aasm_event).to_sym

    if folio_console_record.aasm
                           .events(possible: true)
                           .any? { |e| e.name == event }
      folio_console_record.send("#{event}!")
      location = request.referer || respond_with_location
      respond_with folio_console_record, location: location
    else
      human_event = AASM::Localizer.new.human_event_name(@klass, event)

      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { error: I18n.t('folio.console.base_controller.invalid_event', event: human_event) }
    end
  end

  private

    def folio_console_name_base(plural: false)
      if plural
        params[:controller].split('/').last
      else
        params[:controller].split('/').last.singularize
      end
    end

    def folio_console_record_variable_name(plural: false)
      "@#{folio_console_name_base(plural: plural)}".to_sym
    end

    def folio_console_record
      instance_variable_get(folio_console_record_variable_name)
    end

    def folio_console_records
      instance_variable_get(folio_console_record_variable_name(plural: true))
    end

    def folio_console_params
      send("#{folio_console_name_base}_params")
    end

    def respond_with_location
      if folio_console_record.destroyed?
        url_for([:console, @klass])
      else
        if folio_console_record.persisted?
          begin
            url_for([:edit, :console, folio_console_record])
          rescue ActionController::UrlGenerationError, NoMethodError
            url_for([:console, @klass])
          end
        end
      end
    end
end
