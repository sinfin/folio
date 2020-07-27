# frozen_string_literal: true

class Folio::Console::Api::AasmController < Folio::Console::Api::BaseController
  def event
    klass = params.require(:klass).safe_constantize

    if klass && klass < ActiveRecord::Base && record = klass.find_by(id: params.require(:id))
      if record.valid?
        event_name = params.require(:aasm_event).to_sym

        event = record.aasm
                      .events(possible: true)
                      .find { |e| e.name == event_name }

        if event && !event.options[:private]
          record.send("#{event_name}!")
          opts = params[:cell_options].permit(:small, :active, :remote)
          render json: {
            data: cell('folio/console/state', record, opts).show,
            meta: {
              flash: {
                success: I18n.t('flash.actions.event.notice')
              }
            } }
        else
          render_failure('invalid_event')
        end
      else
        render_failure('invalid_record')
      end
    else
      render_failure
    end
  end

  private
    def render_failure(base = 'failure')
      render json: {
        errors: [
          {
            status: 422,
            title: t(".#{base}_title"),
            detail: t(".#{base}_detail")
          }
        ]
      }, status: 422
    end

  #   if folio_console_record.valid?
  #     event = folio_console_record.aasm
  #                                 .events(possible: true)
  #                                 .find { |e| e.name == event_name }

  #     if event && !event.options[:private]
  #       folio_console_record.send("#{event_name}!")
  #       location = request.referer || respond_with_location
  #       respond_with folio_console_record, location: location
  #     else
  #       human_event = AASM::Localizer.new.human_event_name(@klass, event_name)

  #       redirect_back fallback_location: url_for([:console, @klass]),
  #                     flash: { error: I18n.t('folio.console.base_controller.invalid_event', event: human_event) }
  #     end
  #   else
  #     alert = I18n.t('flash.actions.update.alert',
  #                    resource_name: @klass.model_name.human)
  #     redirect_to respond_with_location(prevalidate: true),
  #                 flash: { alert: alert }
  #   end

  #   render json: { data: scope }
  # else
  #   render json: { data: [] }
  # end
end
