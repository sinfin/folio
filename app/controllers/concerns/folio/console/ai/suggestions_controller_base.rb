# frozen_string_literal: true

module Folio::Console::Ai::SuggestionsControllerBase
  extend ActiveSupport::Concern

  included do
    skip_before_action :add_root_breadcrumb, raise: false
    skip_before_action :update_current_user_console_url, raise: false
    skip_before_action :set_show_current_user_console_url_bar, raise: false

    before_action :folio_ai_ensure_feature_enabled!
  end

  def create
    result = folio_ai_suggestion_generator.call

    if result.success?
      render json: folio_ai_success_response(result)
    else
      render json: folio_ai_error_response(result),
             status: folio_ai_status_for(result.error_code)
    end
  end

  private
    def folio_ai_suggestion_generator
      Folio::Ai::SuggestionGenerator.new(site: folio_ai_site,
                                         user: folio_ai_user,
                                         integration_key: folio_ai_params[:integration_key],
                                         field_key: folio_ai_params[:field_key],
                                         context: folio_ai_context,
                                         instructions: folio_ai_params[:instructions],
                                         persist_instructions: folio_ai_persist_instructions?,
                                         host_eligible: folio_ai_host_eligible?,
                                         suggestion_count: folio_ai_suggestion_count,
                                         provider_adapter: folio_ai_provider_adapter)
    end

    def folio_ai_success_response(result)
      {
        data: {
          suggestions: result.suggestions.map(&:as_json),
          user_instructions: result.user_instruction.to_s,
          provider: result.provider,
          model: result.model,
        }
      }
    end

    def folio_ai_error_response(result)
      code = folio_ai_public_error_code(result.error_code)

      {
        error_code: code,
        message: folio_ai_error_message(code),
        data: {
          suggestions: [],
          user_instructions: result.user_instruction.to_s,
        },
      }
    end

    def folio_ai_public_error_code(error_code)
      return :feature_disabled if error_code == :global_disabled

      error_code
    end

    def folio_ai_error_message(error_code)
      I18n.t("folio.console.ai.errors.#{error_code}",
             default: I18n.t("folio.console.ai.errors.provider_error"))
    end

    def folio_ai_status_for(error_code)
      case folio_ai_public_error_code(error_code)
      when :feature_disabled
        :forbidden
      when :record_not_ready, :missing_context, :invalid_context, :host_ineligible
        :unprocessable_entity
      when :provider_timeout, :provider_rate_limited, :rate_limited
        :too_many_requests
      else
        :unprocessable_entity
      end
    end

    def folio_ai_ensure_feature_enabled!
      return if Folio::Ai.enabled?

      render json: {
        error_code: :feature_disabled,
        message: folio_ai_error_message(:feature_disabled),
        data: { suggestions: [] },
      }, status: :forbidden
    end

    def folio_ai_params
      params.permit(:integration_key,
                    :field_key,
                    :instructions,
                    :persist_instructions,
                    :suggestion_count)
    end

    def folio_ai_persist_instructions?
      ActiveModel::Type::Boolean.new.cast(folio_ai_params[:persist_instructions])
    end

    def folio_ai_suggestion_count
      value = folio_ai_params[:suggestion_count].to_i

      if value.positive?
        [value, 10].min
      else
        Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT
      end
    end

    def folio_ai_site
      Folio::Current.site
    end

    def folio_ai_user
      Folio::Current.user
    end

    def folio_ai_context
      {}
    end

    def folio_ai_host_eligible?
      true
    end

    def folio_ai_provider_adapter
      nil
    end
end
