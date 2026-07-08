# frozen_string_literal: true

class Folio::Ai::BatchSuggestionGenerator
  DEFAULT_BATCH_SUGGESTION_COUNT = 1
  ERROR_CODES = {
    Folio::Ai::ProviderTimeoutError => :provider_timeout,
    Folio::Ai::ProviderRateLimitError => :provider_rate_limited,
    Folio::Ai::ProviderModelUnavailableError => :provider_model_unavailable,
    Folio::Ai::ResponseInvalidError => :response_invalid,
    Folio::Ai::CostLimitExceededError => :cost_limit_exceeded,
    Folio::Ai::RateLimitExceededError => :rate_limited,
    Folio::Ai::ProviderError => :provider_error,
    Folio::Ai::UnknownProviderError => :provider_error,
    ArgumentError => :provider_error,
  }.freeze

  Result = Struct.new(:results, keyword_init: true)

  OutputField = Struct.new(:key,
                           :component_id,
                           :label,
                           :field,
                           keyword_init: true)
  ProviderField = OutputField

  def initialize(site:,
                 user:,
                 integration_key:,
                 field_key:,
                 fields:,
                 context: {},
                 instructions: nil,
                 provider_adapter_class_name: nil,
                 provider_adapter: nil)
    @site = site
    @user = user
    @integration_key = integration_key
    @field_key = field_key
    @fields = fields
    @context = context || {}
    @instructions = instructions
    @provider_adapter_class_name = provider_adapter_class_name
    @provider_adapter = provider_adapter
  end

  def call
    @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    availability = availability_result
    return failure_result(availability.reason, field: availability.field) unless availability.available?

    @instruction = effective_instruction
    @provider_config = Folio::Ai::ProviderConfig.new(site:, integration_key:, field_key:).call
    prompt = compose_prompt
    check_request!(prompt.prompt)

    generate_safely(prompt: prompt.prompt, field: availability.field)
  rescue *ERROR_CODES.keys => e
    failure_result(ERROR_CODES.fetch(e.class, :provider_error))
  end

  private
    attr_reader :site,
                :user,
                :integration_key,
                :field_key,
                :fields,
                :context,
                :instructions,
                :provider_adapter_class_name,
                :provider_adapter,
                :started_at,
                :instruction,
                :provider_config

    def availability_result
      Folio::Ai::Availability.new(site:,
                                  integration_key:,
                                  field_key:).call
    end

    def output_fields
      @output_fields ||= Array(fields).filter_map do |field_params|
        data = field_params.to_h.with_indifferent_access
        key = data[:field_key].to_s
        next if key.blank?

        OutputField.new(key:,
                        component_id: data[:component_id].presence || "folio_ai_text_suggestions",
                        label: data[:field_label].presence || key.humanize,
                        field: registry_field(data))
      end
    end

    def registry_field(data)
      Folio::Ai.registry.field(data[:integration_key].presence || integration_key, data[:field_key])
    end

    def effective_instruction
      return instructions.to_s unless instructions.nil?
      return "" if user.blank? || site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user:,
                                                        site:,
                                                        integration_key:,
                                                        field_key:).instruction.to_s
    end

    def compose_prompt
      Folio::Ai::PromptComposer.new(default_prompt: instruction.presence || site.ai_prompt_for(integration_key:, field_key:),
                                    context:).call
    end

    def check_request!(prompt)
      Folio::Ai::RequestGuard.new(site:,
                                  user:,
                                  integration_key:,
                                  field_key:,
                                  prompt:).check!
    end

    def generate_safely(prompt:, field:)
      generate_with_tracking(prompt:,
                             field:,
                             provider_config:)
    rescue Folio::Ai::ProviderModelUnavailableError
      fallback_config = fallback_provider_config(provider_config)
      raise unless fallback_config

      track_model_fallback(fallback_config)

      generate_with_tracking(prompt:,
                             field:,
                             provider_config: fallback_config)
    end

    def generate_with_tracking(prompt:, field:, provider_config:)
      adapter = batch_provider_adapter(provider_config)

      Folio::Ai.track(:suggestion_generation_requested,
                      tracking_payload(provider_config:,
                                       suggestion_count: output_fields.length))

      suggestions_by_field = adapter.generate_batch_suggestions(prompt:,
                                                                field:,
                                                                fields: output_fields,
                                                                suggestion_count: DEFAULT_BATCH_SUGGESTION_COUNT)
      result = success_result(suggestions_by_field:, provider_config:)

      track_generation_succeeded(provider_config:)

      result
    end

    def batch_provider_adapter(provider_config)
      explicit_provider_adapter || provider_adapter || Folio::Ai.config.provider_adapter(provider: provider_config.provider,
                                                                                        model: provider_config.model)
    end

    def explicit_provider_adapter
      return @explicit_provider_adapter if defined?(@explicit_provider_adapter)

      provider_adapter_class = provider_adapter_class_name&.safe_constantize
      @explicit_provider_adapter = provider_adapter_class&.new
    end

    def fallback_provider_config(provider_config)
      return if provider_adapter.present?
      return if explicit_provider_adapter.present?
      return unless Folio::Ai.config.model_fallback_enabled?

      fallback_model = Folio::Ai.config.default_model(provider_config.provider)
      return if fallback_model.blank? || fallback_model == provider_config.model

      Folio::Ai::ProviderConfig::Result.new(provider: provider_config.provider,
                                            model: fallback_model,
                                            requested_model: provider_config.model,
                                            warnings: [
                                              {
                                                code: :model_fallback,
                                                requested_model: provider_config.model,
                                                fallback_model:,
                                              },
                                            ])
    end

    def success_result(suggestions_by_field:, provider_config:)
      Result.new(results: output_fields.index_with do |output_field|
                   suggestions = suggestions_by_field.fetch(output_field.key) do
                     raise Folio::Ai::ResponseInvalidError, "AI provider omitted suggestions for #{output_field.key}"
                   end

                   success(output_field, suggestions:, provider_config:)
                 end.transform_keys(&:component_id))
    end

    def success(output_field, suggestions:, provider_config:)
      Folio::Ai::SuggestionGenerator::Result.new(success: true,
                                                 suggestions:,
                                                 field: output_field.field,
                                                 provider: provider_config.provider,
                                                 model: provider_config.model,
                                                 user_instruction: instruction,
                                                 warnings: provider_config.warnings || [])
    end

    def failure_result(error_code, field: nil)
      track_generation_failed(error_code)

      Result.new(results: output_fields.index_with do |output_field|
                   failure(output_field, error_code, field: field || output_field.field)
                 end.transform_keys(&:component_id))
    end

    def failure(output_field, error_code, field: nil)
      Folio::Ai::SuggestionGenerator::Result.new(success: false,
                                                 suggestions: [],
                                                 error_code:,
                                                 field: field || output_field.field,
                                                 user_instruction: instruction.to_s,
                                                 warnings: [])
    end

    def track_generation_succeeded(provider_config:)
      Folio::Ai.track(:suggestion_generation_succeeded,
                      tracking_payload(provider_config:,
                                       suggestion_count: output_fields.length,
                                       latency_ms: elapsed_ms))
    end

    def track_generation_failed(error_code)
      Folio::Ai.track(:suggestion_generation_failed,
                      tracking_payload(provider_config:,
                                       error_code:,
                                       latency_ms: elapsed_ms))
    end

    def track_model_fallback(provider_config)
      warning = provider_config.warnings.first

      Folio::Ai.track(:provider_model_fallback,
                      tracking_payload(provider_config:,
                                       warning_code: warning[:code],
                                       requested_model: warning[:requested_model],
                                       fallback_model: warning[:fallback_model]))
    end

    def tracking_payload(provider_config: nil,
                         suggestion_count: nil,
                         latency_ms: nil,
                         error_code: nil,
                         warning_code: nil,
                         requested_model: nil,
                         fallback_model: nil)
      {
        site_id: site&.id,
        user_id: user&.id,
        integration_key: integration_key.to_s,
        field_key: field_key.to_s,
        provider: provider_config&.provider,
        model: provider_config&.model,
        requested_model: requested_model || provider_config&.requested_model,
        fallback_model:,
        suggestion_count:,
        latency_ms:,
        error_code:,
        warning_code:,
      }.compact
    end

    def elapsed_ms
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).round
    end
end
