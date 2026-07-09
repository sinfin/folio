# frozen_string_literal: true

# Renders grouped AI controls that trigger suggestions for child AI inputs.
class Folio::Ai::Console::TextSuggestionsGroupComponent < Folio::Console::ApplicationComponent
  def initialize(form:, key:, fields: nil, label: nil, instructions: nil)
    @form = form
    @record = form.object
    @fields = Array(fields)
    @key = key.to_s
    @label = label
    @instructions = instructions
  end

  def render?
    Folio::Ai.config.enabled? &&
      record_key.present? &&
      @record.respond_to?(:persisted?) &&
      @record.persisted? &&
      site_enabled? &&
      provider_available? &&
      group.present? &&
      field_items.present?
  end

  private
    def component_data
      stimulus_controller("f-ai-c-text-suggestions-group",
                          values: {
                            url: text_suggestions_url,
                            klass: @record.class.name,
                            record_id: @record.id,
                            key: group.fetch(:key),
                            component_id: component_id,
                            suggestion_count: Folio::Ai::GROUPED_SUGGESTION_COUNT,
                            fields: field_items_for_payload.to_json,
                            open: false,
                          },
                          action: {
                            "f-ai-c-text-suggestions-group/message": "onMessage",
                            "f-ai-input:closeGroup": "close",
                          })
    end

    def close_data
      stimulus_merge(stimulus_target("closeButton"),
                     stimulus_action(click: "close"))
    end

    def instructions_data
      stimulus_merge(stimulus_controller("f-input-autosize", inline: true),
                     stimulus_target("instructions"))
    end

    def field_items
      @field_items ||= group.fetch(:fields).filter_map do |field_key|
        field_hash = field_config_by_key[field_key] || {}
        field = Folio::Ai.registry.field(record_key, field_key)
        next unless field

        field.merge(component_id: field_hash[:component_id].presence || input_component_id(field_key))
      end
    end

    def field_items_for_payload
      field_items.map { |field| field.slice(:key, :component_id) }
    end

    def field_config_by_key
      @field_config_by_key ||= @fields.each_with_object({}) do |field_config, hash|
        field_hash = field_config_hash(field_config)
        field_key = field_hash[:key].to_s
        hash[field_key] = field_hash if field_key.present?
      end
    end

    def field_config_hash(field_config)
      case field_config
      when Hash
        field_config.symbolize_keys
      else
        { key: field_config }
      end
    end

    def component_id
      @component_id ||= "folio_ai_text_suggestions_group_#{dom_id_token(@form.object_name)}_#{dom_id_token(group.fetch(:key))}"
    end

    def input_component_id(field_key)
      "folio_ai_text_suggestions_#{input_id(field_key)}"
    end

    def input_id(field_key)
      dom_id_token("#{@form.object_name}_#{field_key}")
    end

    def dom_id_token(value)
      value.to_s.gsub(/[^a-zA-Z0-9_-]/, "_")
    end

    def record_key
      @record.class.table_name if @record&.class&.respond_to?(:table_name)
    end

    def group
      @group ||= Folio::Ai.registry.group(record_key, @key)
    end

    def site
      @record.respond_to?(:site) ? @record.site : Folio::Current.site
    end

    def site_enabled?
      !site.respond_to?(:ai_enabled?) || site.ai_enabled?
    end

    def provider_available?
      provider_key = site&.respond_to?(:ai_provider) ? site.ai_provider : Folio::Ai.config.default_provider
      provider_model = site&.respond_to?(:ai_model) ? site.ai_model : Folio::Ai.config.default_model(provider_key)

      Folio::Ai.provider_for(key: provider_key,
                             model: provider_model)
      true
    rescue Folio::Ai::ProviderError, ArgumentError, KeyError
      false
    end

    def text_suggestions_url
      Folio::Engine.routes.url_helpers.console_api_ai_text_suggestions_path
    end

    def instructions
      return @instructions.to_s unless @instructions.nil?

      user_instruction.presence || site_prompt.to_s
    end

    def user_instruction
      return if current_user.blank? || site.blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: current_user,
                                                        site:,
                                                        record_key:,
                                                        key: group.fetch(:key)).instruction.to_s
    end

    def current_user
      Folio::Current.user
    end

    def site_prompt
      return unless site.respond_to?(:ai_prompt_for)

      site.ai_prompt_for(record_key:,
                         key: group.fetch(:key),
                         grouped: true)
    end

    def button_label
      @label.presence || t(".button")
    end
end
