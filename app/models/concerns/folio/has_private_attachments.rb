# frozen_string_literal: true

module Folio::HasPrivateAttachments
  extend ActiveSupport::Concern

  included do
    has_many :private_attachments, -> { ordered },
                                   class_name: 'Folio::PrivateAttachment',
                                   as: :attachmentable,
                                   foreign_key: :attachmentable_id,
                                   dependent: :destroy
    accepts_nested_attributes_for :private_attachments, allow_destroy: true,
                                                        reject_if: :all_blank
  end
end
