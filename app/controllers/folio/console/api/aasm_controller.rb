# frozen_string_literal: true

class Folio::Console::Api::AasmController < Folio::Console::Api::BaseController
  def event
    klass = params.require(:klass).safe_constantize

    if klass && klass < ActiveRecord::Base && record = klass.find_by(id: params.require(:id))
      if record.valid?
        event_name = params.require(:aasm_event).to_sym

        event = record.allowed_events_for(Folio::Current.user).find { |e| e.name == event_name }

        if event && !event.options[:private]
          record = handle_record_before_event(record)
          record.send("#{event_name}!")

          if params[:event_email_enabled] == "1"
            if %i[event_email_subject event_email_text email].all? { |key| params[key].present? }
              Folio::AasmMailer.event(params[:email], params[:event_email_subject], params[:event_email_text])
                               .deliver_later
            end
          end

          if params[:cell_options]
            opts = {
              small: params[:cell_options][:small].presence,
              active: params[:cell_options][:active].presence,
              remote: params[:cell_options][:remote].presence,
              button: params[:cell_options][:button].presence,
            }
          else
            opts = {}
          end

          if record.errors.any?
            if params[:reload_form].present?
              return render_failure("invalid_record", record:)
            else
              error_response = {
                errors: record.errors.full_messages.map { |message|
                  {
                    status: 422,
                    title: t(".invalid_record_title"),
                    detail: message
                  }
                }
              }
              return render json: error_response, status: 422
            end
          end

          render json: {
            data: cell("folio/console/state", record, opts).show,
            meta: params[:reload_form] ? nil : {
              flash: {
                success: I18n.t("flash.actions.event.notice", resource_name: record.model_name.human)
              }
            } }
        else
          render_failure("invalid_event")
        end
      else
        render_failure("invalid_record", record:)
      end
    else
      render_failure
    end
  end

  private
    def render_failure(base = "failure", record: nil)
      if params[:reload_form].present? && record.present? && record.errors.any?
        validation_box = Folio::Console::Ui::ValidationBoxComponent.new(
          errors: record.errors,
          record:
        )
        validation_box_html = render_to_string(validation_box, layout: false)
        error_response = {
          errors: [
            {
              status: 422,
              title: t(".#{base}_title"),
              detail: t(".#{base}_detail")
            }
          ],
          meta: { validation_box_html: }
        }
      else
        error_response = {
          errors: [
            {
              status: 422,
              title: t(".#{base}_title"),
              detail: t(".#{base}_detail")
            }
          ]
        }
      end

      render json: error_response, status: 422
    end

    def handle_record_before_event(record)
      record
    end
end
