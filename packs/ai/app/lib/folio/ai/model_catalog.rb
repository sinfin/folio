# frozen_string_literal: true

class Folio::Ai::ModelCatalog
  CACHE_VERSION = 1

  Option = Struct.new(:id,
                      :label,
                      :provider,
                      :available,
                      :source,
                      :cost_tier,
                      :default,
                      keyword_init: true) do
    def available?
      available != false
    end

    def default?
      default == true
    end

    def select_label
      [
        label.presence || id,
        cost_tier_label,
        id_label,
      ].compact.join(" - ")
    end

    private
      def cost_tier_label
        cost_tier.to_s.humanize if cost_tier.present?
      end

      def id_label
        id if label.present? && label != id
      end
  end

  Result = Struct.new(:models, :verified, :error, keyword_init: true) do
    def verified?
      verified == true
    end

    def model_available?(id)
      return nil unless verified?

      models.any? { |model| model.id == id && model.available? }
    end
  end

  Status = Struct.new(:available, :verified, :model, keyword_init: true) do
    def available?
      verified? && available == true
    end

    def unavailable?
      verified? && available == false
    end

    def verified?
      verified == true
    end
  end

  def initialize(provider:, api_key: nil)
    @provider = provider.to_sym
    @api_key = api_key
  end

  def result(selected: nil)
    catalog = cached_live_catalog
    models = options_from_catalog(catalog, selected:)

    Result.new(models:,
               verified: catalog["verified"] == true,
               error: catalog["error"])
  end

  def status(model)
    return Status.new(available: nil, verified: false, model: nil) if model.blank?

    catalog_result = result(selected: model)
    available = catalog_result.model_available?(model)

    Status.new(available:,
               verified: catalog_result.verified?,
               model: catalog_result.models.find { |option| option.id == model })
  end

  def fallback_model_for(model)
    fallback_model = Folio::Ai.default_model(provider)
    return if fallback_model.blank? || fallback_model == model

    fallback_status = status(fallback_model)
    fallback_model unless fallback_status.unavailable?
  end

  private
    attr_reader :provider,
                :api_key

    def cached_live_catalog
      return @cached_live_catalog if defined?(@cached_live_catalog)

      @cached_live_catalog = Rails.cache.fetch(cache_key, expires_in: Folio::Ai.model_catalog_cache_ttl) do
        fetch_live_catalog
      end
    rescue Folio::Ai::ProviderError, KeyError, ArgumentError => e
      @cached_live_catalog = configured_catalog(error: "#{e.class.name}: #{e.message}")
    end

    def fetch_live_catalog
      models = Folio::Ai.provider_adapter_class(provider)
                        .list_models(api_key: api_key_for_provider,
                                     timeout: Folio::Ai.provider_request_timeout)

      {
        "verified" => true,
        "models" => models.map { |model| serialized_model(model) },
        "fetched_at" => Time.current.iso8601,
      }
    end

    def configured_catalog(error: nil)
      {
        "verified" => false,
        "models" => [],
        "error" => error,
      }.compact
    end

    def options_from_catalog(catalog, selected:)
      if catalog["verified"]
        live_options(catalog["models"])
      else
        configured_options
      end.then do |options|
        append_selected_option(options, selected:, verified: catalog["verified"])
      end
    end

    def live_options(models)
      metadata = configured_model_metadata

      Array(models).map do |attributes|
        id = attributes.fetch("id")
        option_metadata = metadata.fetch(id, {})

        Option.new(id:,
                   label: option_metadata["label"].presence || attributes["label"].presence || id,
                   provider: provider.to_s,
                   available: true,
                   source: :provider,
                   cost_tier: option_metadata["cost_tier"],
                   default: option_metadata["default"])
      end
    end

    def configured_options
      configured_model_metadata.map do |id, metadata|
        Option.new(id:,
                   label: metadata["label"].presence || id,
                   provider: provider.to_s,
                   available: true,
                   source: :configured,
                   cost_tier: metadata["cost_tier"],
                   default: metadata["default"])
      end
    end

    def append_selected_option(options, selected:, verified:)
      selected = selected.to_s
      return options if selected.blank?
      return options if options.any? { |option| option.id == selected }

      options + [
        Option.new(id: selected,
                   label: selected,
                   provider: provider.to_s,
                   available: verified != true,
                   source: :selected,
                   cost_tier: nil,
                   default: false),
      ]
    end

    def configured_model_metadata
      configured = normalized_provider_model_options
      default_model = Folio::Ai.provider_models[provider]
      configured[default_model.to_s] ||= { "label" => default_model.to_s, "default" => true } if default_model.present?
      configured
    end

    def normalized_provider_model_options
      raw_options = Folio::Ai.provider_model_options
      provider_options = raw_options[provider] || raw_options[provider.to_s] || {}

      case provider_options
      when Hash
        provider_options.each_with_object({}) do |(id, metadata), normalized|
          normalized[id.to_s] = normalize_metadata(metadata)
        end
      when Array
        provider_options.each_with_object({}) do |item, normalized|
          id, metadata = array_item_id_and_metadata(item)
          normalized[id] = normalize_metadata(metadata) if id.present?
        end
      else
        {}
      end
    end

    def array_item_id_and_metadata(item)
      return [item.to_s, {}] unless item.is_a?(Hash)

      id = item[:id] || item["id"]
      [id.to_s, item]
    end

    def normalize_metadata(metadata)
      return {} unless metadata.is_a?(Hash)

      metadata.stringify_keys.slice("label", "cost_tier", "default")
    end

    def serialized_model(model)
      {
        "id" => model.id,
        "label" => model.label,
        "created_at" => model.created_at,
      }
    end

    def api_key_for_provider
      key = api_key.presence || Folio::Ai.provider_api_key(provider)
      raise ArgumentError, "AI provider API key is blank" if key.blank?

      key
    end

    def cache_key
      "folio/ai/model_catalog/v#{CACHE_VERSION}/#{provider}"
    end
end
