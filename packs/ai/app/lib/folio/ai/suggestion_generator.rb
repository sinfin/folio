# frozen_string_literal: true

class Folio::Ai::SuggestionGenerator
  Result = Struct.new(:success,
                      :suggestions,
                      :error_code,
                      :field,
                      :provider,
                      :model,
                      :user_instruction,
                      :warnings,
                      keyword_init: true) do
    def success?
      success
    end
  end

  def initialize(site:,
                 user:,
                 integration_key:,
                 field_key:,
                 context: {},
                 instructions: nil,
                 persist_instructions: false,
                 host_eligible: true,
                 suggestion_count: Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT,
                 provider_adapter: nil)
    @site = site
    @user = user
    @integration_key = integration_key
    @field_key = field_key
    @context = context || {}
    @instructions = instructions
    @persist_instructions = persist_instructions
    @host_eligible = host_eligible
    @suggestion_count = suggestion_count
    @provider_adapter = provider_adapter
  end

  def call
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    provider_config = nil
    instruction = nil

    availability = availability_result
    unless availability.available?
      return failure_with_tracking(availability.reason,
                                   started_at:,
                                   field: availability.field)
    end

    instruction = effective_instruction
    provider_config = Folio::Ai::ProviderConfig.new(site:, integration_key:, field_key:).call
    prompt = compose_prompt(instruction)
    check_request!(prompt.prompt)
    generate_safely(prompt: prompt.prompt,
                    field: availability.field,
                    provider_config:,
                    user_instruction: instruction,
                    started_at:)
  rescue Folio::Ai::ProviderTimeoutError
    failure_with_tracking(:provider_timeout, started_at:, provider_config:, user_instruction: instruction)
  rescue Folio::Ai::ProviderRateLimitError
    failure_with_tracking(:provider_rate_limited, started_at:, provider_config:, user_instruction: instruction)
  rescue Folio::Ai::ProviderModelUnavailableError
    failure_with_tracking(:provider_model_unavailable, started_at:, provider_config:, user_instruction: instruction)
  rescue Folio::Ai::ResponseInvalidError
    failure_with_tracking(:response_invalid, started_at:, provider_config:, user_instruction: instruction)
  rescue Folio::Ai::CostLimitExceededError
    failure_with_tracking(:cost_limit_exceeded, started_at:, provider_config:, user_instruction: instruction)
  rescue Folio::Ai::RateLimitExceededError
    failure_with_tracking(:rate_limited, started_at:, provider_config:, user_instruction: instruction)
  rescue Folio::Ai::ProviderError, Folio::Ai::UnknownProviderError, ArgumentError
    failure_with_tracking(:provider_error, started_at:, provider_config:, user_instruction: instruction)
  end

  private
    attr_reader :site,
                :user,
                :integration_key,
                :field_key,
                :context,
                :instructions,
                :persist_instructions,
                :host_eligible,
                :suggestion_count,
                :provider_adapter

    def availability_result
      Folio::Ai::Availability.new(site:,
                                  integration_key:,
                                  field_key:,
                                  host_eligible:).call
    end

    def effective_instruction
      if persist_instructions
        persist_instruction!
      elsif instructions.nil?
        stored_instruction
      else
        instructions.to_s
      end
    end

    def persist_instruction!
      Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                     site:,
                                                     integration_key:,
                                                     field_key:,
                                                     instruction: instructions.to_s)
                                 .instruction
                                 .tap do
        Folio::Ai.track(:user_instruction_saved, tracking_payload)
      end
    end

    def stored_instruction
      Folio::Ai::UserInstruction.find_or_initialize_for(user:,
                                                        site:,
                                                        integration_key:,
                                                        field_key:).instruction.to_s
    end

    def compose_prompt(instruction)
      Folio::Ai::PromptComposer.new(default_prompt: site.ai_prompt_for(integration_key:, field_key:),
                                    user_instruction: instruction,
                                    context:).call
    end

    def check_request!(prompt)
      Folio::Ai::RequestGuard.new(site:,
                                  user:,
                                  integration_key:,
                                  field_key:,
                                  prompt:).check!
    end

    def generate_safely(prompt:, field:, provider_config:, user_instruction:, started_at:)
      generate_with_tracking(prompt:,
                             field:,
                             provider_config:,
                             user_instruction:,
                             started_at:)
    rescue Folio::Ai::ProviderModelUnavailableError
      fallback_config = fallback_provider_config(provider_config)
      raise unless fallback_config

      track_model_fallback(fallback_config)

      generate_with_tracking(prompt:,
                             field:,
                             provider_config: fallback_config,
                             user_instruction:,
                             started_at:)
    end

    def generate_with_tracking(prompt:, field:, provider_config:, user_instruction:, started_at:)
      adapter = provider_adapter || Folio::Ai.provider_adapter(provider: provider_config.provider,
                                                               model: provider_config.model)

      Folio::Ai.track(:suggestion_generation_requested, tracking_payload(provider_config:,
                                                                         suggestion_count:))

      result = success(adapter.generate_suggestions(prompt:,
                                                    field:,
                                                    suggestion_count:),
                       field:,
                       provider_config:,
                       user_instruction:)

      track_generation_succeeded(result, started_at:, provider_config:)

      result
    end

    def fallback_provider_config(provider_config)
      return if provider_adapter.present?
      return unless Folio::Ai.model_fallback_enabled?

      fallback_model = Folio::Ai.default_model(provider_config.provider)
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

    def success(suggestions, field:, provider_config:, user_instruction:)
      Result.new(success: true,
                 suggestions:,
                 field:,
                 provider: provider_config.provider,
                 model: provider_config.model,
                 user_instruction:,
                 warnings: provider_config.warnings || [])
    end

    def failure(error_code, field: nil, user_instruction: nil)
      Result.new(success: false,
                 suggestions: [],
                 error_code:,
                 field:,
                 user_instruction:,
                 warnings: [])
    end

    def failure_with_tracking(error_code, started_at:, field: nil, provider_config: nil, user_instruction: nil)
      failure(error_code, field:, user_instruction:).tap do
        track_generation_failed(error_code, started_at:, provider_config:)
      end
    end

    def track_generation_succeeded(result, started_at:, provider_config:)
      Folio::Ai.track(:suggestion_generation_succeeded,
                      tracking_payload(provider_config:,
                                       suggestion_count: result.suggestions.length,
                                       latency_ms: latency_ms(started_at)))
    end

    def track_generation_failed(error_code, started_at:, provider_config: nil)
      Folio::Ai.track(:suggestion_generation_failed,
                      tracking_payload(provider_config:,
                                       error_code:,
                                       latency_ms: latency_ms(started_at)))
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
                         provider: nil,
                         model: nil,
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
        provider: provider || provider_config&.provider,
        model: model || provider_config&.model,
        requested_model: requested_model || provider_config&.requested_model,
        fallback_model:,
        suggestion_count:,
        latency_ms:,
        error_code:,
        warning_code:,
      }.compact
    end

    def latency_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).round
    end
end
