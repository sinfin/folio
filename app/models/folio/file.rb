# frozen_string_literal: true

module Folio
  class File < ApplicationRecord
    include Taggable
    include SanitizeFilename

    paginates_per nil
    max_paginates_per nil

    dragonfly_accessor :file do
      after_assign :sanitize_filename
    end

    # Relations
    has_many :file_placements, class_name: 'Folio::FilePlacement',
                               dependent: :destroy
    has_many :placements, through: :file_placements
    has_many :cover_placements, class_name: 'Folio::CoverPlacement',
                                dependent: :destroy

    # Validations
    validates :file, :type,
              presence: true

    # Scopes
    scope :ordered, -> { order(updated_at: :desc) }

    before_save :set_mime_type
    after_save :touch_placements

    def title
      file_name
    end

    def file_extension
      Mime::Type.lookup(mime_type).symbol
    end

    private

      def touch_placements
        file_placements.each(&:touch)
        cover_placements.each(&:touch)
      end

      def set_mime_type
        return unless file.present?
        return unless respond_to?(:mime_type)
        self.mime_type = file.mime_type
      end
  end
end

# == Schema Information
#
# Table name: folio_files
#
#  id              :bigint(8)        not null, primary key
#  file_uid        :string
#  file_name       :string
#  type            :string
#  thumbnail_sizes :text             default("--- {}\n")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  file_size       :bigint(8)
#  mime_type       :string(255)
#  additional_data :json
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
