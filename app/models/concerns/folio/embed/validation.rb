# frozen_string_literal: true

module Folio::Embed::Validation
  extend ActiveSupport::Concern

  included do
    validate :validate_folio_embed_data
  end

  private
    def validate_folio_embed_data
      return unless respond_to?(:folio_embed_data)

      Folio::Embed.validate_record(record: self, attribute_name: :folio_embed_data)
    end
end
