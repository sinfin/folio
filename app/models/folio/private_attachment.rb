# frozen_string_literal: true

class Folio::PrivateAttachment < Folio::ApplicationRecord
  include Folio::HasHashId
  include Folio::Positionable
  include Folio::SanitizeFilename
  extend Folio::InheritenceBaseNaming

  dragonfly_accessor :file do
    after_assign :sanitize_filename
  end

  belongs_to :attachmentable, polymorphic: true,
                              touch: true,
                              required: false

  # Validations
  validates :file,
            presence: true

  def title
    super.presence || file_name
  end

  def file_extension
    if file_mime_type.include?("msword")
      file_name.include?("docx") ? :docx : :doc
    else
      Mime::Type.lookup(file_mime_type).symbol
    end
  end

  def self.hash_id_additional_classes
    [Folio::File]
  end
end

# == Schema Information
#
# Table name: folio_private_attachments
#
#  id                  :bigint(8)        not null, primary key
#  attachmentable_type :string
#  attachmentable_id   :bigint(8)
#  type                :string
#  file_uid            :string
#  file_name           :string
#  title               :text
#  alt                 :string
#  thumbnail_sizes     :text
#  position            :integer
#  file_width          :integer
#  file_height         :integer
#  file_size           :bigint(8)
#  additional_data     :json
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  hash_id             :string
#  file_mime_type      :string
#
# Indexes
#
#  index_folio_private_attachments_on_attachmentable  (attachmentable_type,attachmentable_id)
#  index_folio_private_attachments_on_type            (type)
#
