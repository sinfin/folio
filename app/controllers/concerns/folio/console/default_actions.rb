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

  def edit
    folio_console_record.valid? if params[:prevalidate]
  end

  def merge
    @folio_console_merge = @klass
    index
    render :index
  end

  def create
    instance_variable_set(folio_console_record_variable_name,
                          @klass.create(folio_console_params))

    if folio_console_record.persisted? && params[:created_from_modal]
      label = folio_console_record.try(:to_console_label) ||
              folio_console_record.try(:to_label) ||
              folio_console_record.try(:title) ||
              folio_console_record.id

      render json: { label: label, id: folio_console_record.id }, layout: false
    else
      respond_with folio_console_record, location: respond_with_location
    end
  end

  def update
    folio_console_record.update(folio_console_params)

    respond_to do |format|
      format.html do
        respond_with folio_console_record, location: respond_with_location
      end
      format.json do
        if folio_console_record.valid?
          respond_with folio_console_record, location: respond_with_location
        else
          errors = [
            {
              status: 422,
              title: I18n.t('flash.actions.update.alert',
                            resource_name: @klass.model_name.human),
              detail: invalid_flash_error,
            }
          ]

          render json: { errors: errors }, status: 422
        end
      end
    end
  end

  def destroy
    folio_console_record.destroy
    respond_with folio_console_record, location: respond_with_location
  end

  def discard
    folio_console_record.discard
    respond_with folio_console_record,
                 location: request.referrer || url_for([:console, @klass])
  end

  def undiscard
    folio_console_record.undiscard
    respond_with folio_console_record,
                 location: request.referrer || url_for([:console, @klass])
  end

  def ancestry
    @klass.transaction do
      params.require(:ancestry).each do |i, hash|
        @klass.find(hash[:id])
              .update!(position: hash[:position],
                       parent_id: hash[:parent_id])
      end
    end

    redirect_to url_for([:console, @klass]),
                flash: { notice: I18n.t('folio.console.base_controller.ancestry.success') }
  rescue
    redirect_to url_for([:console, @klass]),
                flash: { error: I18n.t('folio.console.base_controller.ancestry.error') }
  end

  def event
    event_name = params.require(:aasm_event).to_sym

    if folio_console_record.valid?
      event = folio_console_record.aasm
                                  .events(possible: true)
                                  .find { |e| e.name == event_name }

      if event && !event.options[:private]
        folio_console_record.send("#{event_name}!")
        location = request.referer || respond_with_location
        respond_with folio_console_record, location: location
      else
        human_event = AASM::Localizer.new.human_event_name(@klass, event_name)

        redirect_back fallback_location: url_for([:console, @klass]),
                      flash: { error: I18n.t('folio.console.base_controller.invalid_event', event: human_event) }
      end
    else
      alert = I18n.t('flash.actions.update.alert',
                     resource_name: @klass.model_name.human)
      redirect_to respond_with_location(prevalidate: true),
                  flash: { alert: alert }
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

    def respond_with_location(prevalidate: nil)
      if folio_console_record.destroyed?
        request.referrer || url_for([:console, @klass])
      else
        if folio_console_record.persisted?
          begin
            url_for([:edit, :console, folio_console_record, prevalidate: prevalidate ? 1 : nil])
          rescue ActionController::UrlGenerationError, NoMethodError
            url_for([:console, @klass, prevalidate: prevalidate ? 1 : nil])
          end
        end
      end
    end

    def invalid_flash_error
      base = I18n.t('flash.actions.update.alert',
                    resource_name: @klass.model_name.human)
      folio_console_record.valid?
      messages = folio_console_record.errors.full_messages
      "#{base} #{messages.join(" ")}"
    end
end
