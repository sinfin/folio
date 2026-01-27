# frozen_string_literal: true

class Folio::Cache::ConsoleInvalidationMetadataComponent < Folio::Console::ApplicationComponent
  def initialize(metadata:)
    @metadata = metadata
  end

  def render?
    @metadata.present?
  end

  private
    attr_reader :metadata

    def display_text
      return metadata.to_s unless metadata.is_a?(Hash)

      case metadata["type"] || metadata[:type]
      when "model"
        display_model
      when "manual"
        display_manual
      when "job"
        display_job
      else
        metadata.map { |k, v| "#{k}: #{v}" }.join(", ")
      end
    end

    def display_model
      model_class = (metadata["class"] || metadata[:class])&.constantize rescue nil
      model_id = metadata["id"] || metadata[:id]

      return metadata.to_s unless model_class && model_id

      begin
        model_instance = model_class.find(model_id)
        label = "#{model_class.model_name.human} ##{model_id}"

        if can_now?(:edit, model_instance)
          begin
            link_to(label, url_for([:edit, :console, model_instance]))
          rescue StandardError
            label
          end
        else
          label
        end
      rescue StandardError
        "#{metadata["class"] || metadata[:class]} ##{model_id}"
      end
    end

    def display_manual
      user_name = metadata["user_name"] || metadata[:user_name]
      if user_name.present?
        t("folio.console.folio.cache.versions.invalidation_metadata.manual_with_user", user: user_name)
      else
        t("folio.console.folio.cache.versions.invalidation_metadata.manual")
      end
    end

    def display_job
      job_class = metadata["class"] || metadata[:class]
      if job_class.present?
        t("folio.console.folio.cache.versions.invalidation_metadata.job_with_class", class: job_class)
      else
        t("folio.console.folio.cache.versions.invalidation_metadata.job")
      end
    end
end
