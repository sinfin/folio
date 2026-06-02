# frozen_string_literal: true

class Folio::Ai::ModelCatalog
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
    models = append_selected_option(configured_options, selected:)

    Result.new(models:,
               verified: false,
               error: nil)
  end

  def status(model)
    return Status.new(available: nil, verified: false, model: nil) if model.blank?

    catalog_result = result(selected: model)

    Status.new(available: nil,
               verified: false,
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

    def append_selected_option(options, selected:)
      selected = selected.to_s
      return options if selected.blank?
      return options if options.any? { |option| option.id == selected }

      options + [
        Option.new(id: selected,
                   label: selected,
                   provider: provider.to_s,
                   available: true,
                   source: :selected,
                   cost_tier: nil,
                   default: false),
      ]
    end

    def configured_model_metadata
      metadata = normalized_provider_model_options
      default_model = Folio::Ai.provider_models[provider]

      configured_model_ids.each_with_object({}) do |id, configured|
        configured[id] = metadata.fetch(id, {}).dup
        configured[id]["default"] = true if id == default_model.to_s && !configured[id].key?("default")
      end.tap do |configured|
        metadata.each do |id, model_metadata|
          configured[id] ||= model_metadata
        end
      end
    end

    def configured_model_ids
      [
        Folio::Ai.provider_models[provider],
        *env_model_ids,
      ].filter_map { |id| id.to_s.presence }.uniq
    end

    def env_model_ids
      Folio::Ai.provider_models_env_value(provider).to_s.split(",").filter_map do |id|
        id.strip.presence
      end
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
end
