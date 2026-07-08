# frozen_string_literal: true

class Folio::Ai::Console::Api::TextSuggestionsController < Folio::Console::Api::BaseController
  def text_suggestions
    render_text_suggestions(instructions: nil, persist_instructions: false)
  end

  def instructions
    render_text_suggestions(instructions: ai_params[:instructions], persist_instructions: true)
  end

  def batch_text_suggestions
    render_batch_text_suggestions(instructions: nil, persist_instructions: false)
  end

  def batch_instructions
    render_batch_text_suggestions(instructions: batch_params[:instructions], persist_instructions: true)
  end

  private
    def render_text_suggestions(instructions:, persist_instructions:)
      return render_missing_message_bus_client_id if message_bus_client_id.blank?

      effective_instructions = effective_instructions_for(text_request, instructions:, persist_instructions:)

      if (error_code = text_request.immediate_error_code)
        return render_component_json(text_request.component(result: text_request.error_result(error_code,
                                                                                             instructions: effective_instructions)))
      end

      request_id = SecureRandom.urlsafe_base64(18)

      Folio::Ai::TextSuggestionsJob.perform_later(request_id:,
                                                  message_bus_client_id:,
                                                  user_id: Folio::Current.user.id,
                                                  site_id: text_request.ai_site.id,
                                                  params: text_request.job_params(instructions: effective_instructions))

      render_component_json(text_request.component(result: text_request.loading_result(instructions: effective_instructions),
                                                   loading: true),
                            meta: { request_id: })
    end

    def render_batch_text_suggestions(instructions:, persist_instructions:)
      return render_missing_message_bus_client_id if batch_message_bus_client_id.blank?
      return render_missing_batch_fields if batch_output_fields.blank?

      effective_instructions = effective_instructions_for(batch_request, instructions:, persist_instructions:)
      error_code = batch_request.immediate_error_code
      panels = batch_panels(error_code:, instructions: effective_instructions)

      return render_batch_panels_json(panels:) if error_code

      request_id = SecureRandom.urlsafe_base64(18)

      Folio::Ai::BatchTextSuggestionsJob.perform_later(request_id:,
                                                       message_bus_client_id: batch_message_bus_client_id,
                                                       user_id: Folio::Current.user.id,
                                                       site_id: batch_request.ai_site.id,
                                                       params: batch_job_params(instructions: effective_instructions))

      render_batch_panels_json(panels:,
                               meta: { request_id: })
    end

    def effective_instructions_for(request, instructions:, persist_instructions:)
      return instructions unless persist_instructions

      request.persist_instruction!(instructions).tap do
        Folio::Ai.track(:user_instruction_saved, request.tracking_payload)
      end
    end

    def text_request
      @text_request ||= build_request(ai_params, raw_current_form_snapshot:)
    end

    def batch_request
      @batch_request ||= build_request(batch_params.except(:fields),
                                       raw_current_form_snapshot: raw_batch_current_form_snapshot)
    end

    def build_request(params, raw_current_form_snapshot:)
      Folio::Ai::TextSuggestionRequest.new(params:,
                                           current_user: Folio::Current.user,
                                           current_site: Folio::Current.site,
                                           current_ability: Folio::Current.ability,
                                           raw_current_form_snapshot:)
    end

    def batch_job_params(instructions:)
      batch_request.job_params(instructions:).slice(:integration_key,
                                                    :field_key,
                                                    :instructions,
                                                    :context,
                                                    :provider_adapter_class_name)
                   .merge(fields: batch_output_fields)
    end

    def batch_output_fields
      @batch_output_fields ||= batch_field_params.filter_map do |field_params|
        next if field_params[:field_key].blank?

        build_request(field_params, raw_current_form_snapshot: nil).output_field_params
      end
    end

    def batch_field_params
      @batch_field_params ||= Array(batch_params[:fields]).map { |field| field.to_h.with_indifferent_access }
    end

    def batch_panels(error_code:, instructions:)
      batch_output_fields.map do |field_params|
        request = build_request(field_params, raw_current_form_snapshot: nil)
        instruction = batch_request.effective_instruction(instructions)
        result = if error_code
          request.error_result(error_code, instructions: instruction)
        else
          request.loading_result(instructions: instruction)
        end

        {
          component_id: field_params[:component_id],
          component: request.component(result:,
                                      loading: error_code.blank?,
                                      loading_suggestion_count: 1,
                                      show_close: false,
                                      show_instructions: false),
        }
      end
    end

    def render_batch_panels_json(panels:, meta: nil)
      payload = {
        data: {
          panels: panels.each_with_object({}) do |panel, hash|
            hash[panel.fetch(:component_id)] = render_to_string(panel.fetch(:component), layout: false)
          end,
        },
      }
      payload[:meta] = meta if meta.present?

      render json: payload
    end

    def render_missing_message_bus_client_id
      render json: {
        errors: [
          {
            title: "message_bus_client_id is required",
          },
        ],
      }, status: :unprocessable_entity
    end

    def render_missing_batch_fields
      render json: {
        errors: [
          {
            title: "fields are required",
          },
        ],
      }, status: :unprocessable_entity
    end

    def message_bus_client_id
      ai_params[:message_bus_client_id].presence
    end

    def batch_message_bus_client_id
      batch_params[:message_bus_client_id].presence
    end

    def raw_current_form_snapshot
      raw_form_snapshot(ai_params)
    end

    def raw_batch_current_form_snapshot
      raw_form_snapshot(batch_params)
    end

    def raw_form_snapshot(source_params)
      snapshot = source_params[:current_form_snapshot]
      return snapshot if snapshot.present?
      return if source_params[:current_form_snapshot_json].blank?

      JSON.parse(source_params[:current_form_snapshot_json])
    rescue JSON::ParserError
      {}
    end

    def ai_params
      params.permit(:klass,
                    :id,
                    :integration_key,
                    :field_key,
                    :component_id,
                    :show_meta,
                    :suggestion_count,
                    :instructions,
                    :message_bus_client_id,
                    :current_form_snapshot_json,
                    current_form_snapshot: {})
    end

    def batch_params
      params.permit(:klass,
                    :id,
                    :integration_key,
                    :field_key,
                    :instructions,
                    :message_bus_client_id,
                    :current_form_snapshot_json,
                    current_form_snapshot: {},
                    fields: [
                      :integration_key,
                      :field_key,
                      :component_id,
                      :show_meta,
                    ])
    end
end
