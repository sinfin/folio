# frozen_string_literal: true

module Folio::Tiptap::Model
  extend ActiveSupport::Concern

  class_methods do
    def has_folio_tiptap?
      folio_tiptap_fields.present?
    end

    def folio_tiptap_fields
      %w[tiptap_content]
    end
  end
end
