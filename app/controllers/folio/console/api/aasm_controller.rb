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
          record = handle_record_before_event(record)
          record.send("#{event_name}!")
          opts = {
            small: params[:cell_options][:small].presence,
            active: params[:cell_options][:active].presence,
            remote: params[:cell_options][:remote].presence,
          }
          render json: {
            data: cell("folio/console/state", record, opts).show,
            meta: {
              flash: {
                success: I18n.t("flash.actions.event.notice", resource_name: record.model_name.human)
              }
            } }
        else
          render_failure("invalid_event")
        end
      else
        render_failure("invalid_record")
      end
    else
      render_failure
    end
  end

  private
    def render_failure(base = "failure")
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

    def handle_record_before_event(record)
      record
    end
end
