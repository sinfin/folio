# frozen_string_literal: true

class Folio::Ai::SuggestionGenerator
  Result = Struct.new(:success,
                      :suggestions,
                      :error_code,
                      :field,
                      :provider,
                      :model,
                      :user_instruction,
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
    availability = availability_result
    return failure(availability.reason, field: availability.field) unless availability.available?

    instruction = effective_instruction
    provider_config = Folio::Ai::ProviderConfig.new(site:, integration_key:, field_key:).call
    prompt = compose_prompt(instruction)
    adapter = provider_adapter || Folio::Ai.provider_adapter(provider: provider_config.provider,
                                                             model: provider_config.model)

    success(adapter.generate_suggestions(prompt: prompt.prompt,
                                         field: availability.field,
                                         suggestion_count:),
            field: availability.field,
            provider_config:,
            user_instruction: instruction)
  rescue Folio::Ai::ProviderTimeoutError
    failure(:provider_timeout)
  rescue Folio::Ai::ProviderRateLimitError
    failure(:provider_rate_limited)
  rescue Folio::Ai::ResponseInvalidError
    failure(:response_invalid)
  rescue Folio::Ai::ProviderError, Folio::Ai::UnknownProviderError, ArgumentError
    failure(:provider_error)
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
                                                     instruction: instructions.to_s).instruction
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

    def success(suggestions, field:, provider_config:, user_instruction:)
      Result.new(success: true,
                 suggestions:,
                 field:,
                 provider: provider_config.provider,
                 model: provider_config.model,
                 user_instruction:)
    end

    def failure(error_code, field: nil)
      Result.new(success: false,
                 suggestions: [],
                 error_code:,
                 field:)
    end
end
