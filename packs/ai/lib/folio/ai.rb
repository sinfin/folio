# frozen_string_literal: true

module Folio::Ai
  DEFAULT_OPENAI_MODEL = "gpt-5.4-mini"

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
  end
end

require_relative "ai/config"
require_relative "../../app/lib/folio/ai/registry"

Folio::Ai.reset_configuration!
Folio::Ai.reset_registry!

require_relative "ai/railtie"
