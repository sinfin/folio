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

  scope :ordered, -> { order(id: :asc) }

  def self.human_type
    "document"
  end

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

  def to_h
    {
      file_size:,
      file_name:,
      type:,
      id:,
    }
  end
end
