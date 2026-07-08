# frozen_string_literal: true

#
# Entry point for AI pack configuration, registry access, providers, and core
# suggestion classes.

module Folio::Ai
  module Console
    module Api
    end
  end

  DEFAULT_DUMMY_MODEL = "dummy"
  DEFAULT_OPENAI_MODEL = "gpt-5.4-mini"
  ProviderError = Class.new(StandardError)
  ResponseError = Class.new(StandardError)

  PACK_ASSETS = {
    javascripts: [],
    stylesheets: [],
  }.freeze

  class << self
    def config
      @config ||= Folio::Ai::Config.new
    end

    def configure
      yield config
    end

    def reset_configuration!
      @config = Folio::Ai::Config.new
    end

    def registry
      @registry ||= Folio::Ai::Registry.new
    end

    def reset_registry!
      @registry = Folio::Ai::Registry.new
    end

    def register_record(...)
      registry.register_record(...)
    end

    def pack_assets
      PACK_ASSETS
    end

    def disabled_by_env?
      ENV.key?("FOLIO_AI_DISABLED")
    end

    def openai_api_key
      ENV["FOLIO_AI_OPENAI_API_KEY"].presence
    end

    def available_providers
      provider_classes.select { |_key, provider_class| provider_class.available? }
    end

    def provider_class(key)
      provider_classes.fetch(key.to_sym)
    rescue KeyError
      raise ArgumentError, "Unknown AI provider: #{key}"
    end

    def provider_for(key: config.default_provider, model: nil)
      key = key.to_sym
      provider_class = available_providers[key]
      raise ProviderError, "AI provider is not available: #{key}" unless provider_class

      provider_class.new(model:)
    end

    private
      def provider_classes
        {
          dummy: Folio::Ai::Providers::Dummy,
          openai: Folio::Ai::Providers::OpenAi,
        }
      end
  end
end

require_relative "ai/config"
require_relative "../../app/lib/folio/ai/registry"
require_relative "../../app/lib/folio/ai/providers/base"
require_relative "../../app/lib/folio/ai/providers/dummy"
require_relative "../../app/lib/folio/ai/providers/open_ai"
require_relative "../../app/lib/folio/ai/text_suggestion_generator"
require_relative "../../app/lib/folio/ai/text_suggestion_request"
require_relative "../../app/components/folio/ai/console/text_suggestions_component"
require_relative "../../app/controllers/folio/ai/console/api/text_suggestions_controller"
require_relative "../../app/models/concerns/folio/ai/site_concern"
require_relative "../../app/models/concerns/folio/ai/user_concern"
require_relative "../../app/models/folio/ai/user_instruction"
require_relative "../../app/jobs/folio/ai/text_suggestions_job"

Folio::Ai.reset_configuration!
Folio::Ai.reset_registry!

require_relative "ai/railtie"
