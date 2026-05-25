# frozen_string_literal: true

module Dummy
  module Ai
    module BlogArticleConcern
      extend ActiveSupport::Concern

      def folio_ai_context(field_key:, current_form_snapshot:)
        {
          title:,
          perex:,
          meta_title:,
          meta_description:,
          current_form_snapshot: current_form_snapshot.presence,
        }.compact
      end

      def folio_ai_suggestions_eligible?(field_key:, current_form_snapshot:)
        persisted? && [title, perex].any?(&:present?)
      end

      def folio_ai_provider_adapter
        Dummy::Ai.demo_provider_adapter_class.new
      end
    end
  end
end
