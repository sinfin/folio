# frozen_string_literal: true

module Folio::HasPrivateAttachments
  extend ActiveSupport::Concern
  include Folio::AcceptsPersistedNestedAttributes

  class_methods do
    def accepts_persisted_nested_attributes_for
      %i[private_attachments]
    end
  end

  included do
    has_many :private_attachments, -> { ordered },
                                   class_name: "Folio::PrivateAttachment",
                                   as: :attachmentable,
                                   foreign_key: :attachmentable_id,
                                   dependent: :destroy

    accepts_nested_attributes_for :private_attachments, allow_destroy: true,
                                                        reject_if: :all_blank
  end
end
