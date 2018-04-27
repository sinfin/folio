# frozen_string_literal: true

module Folio
  class File < ApplicationRecord
    include Taggable

    paginates_per nil
    max_paginates_per nil

    dragonfly_accessor :file do
      after_assign :sanitize_filename
    end

    # Relations
    has_many :file_placements, class_name: 'Folio::FilePlacement', dependent: :destroy

    # Validations
    validates :file, :type, presence: true

    # Scopes
    scope :ordered, -> { order(updated_at: :desc) }

    def title
      file_name
    end

    private

      def sanitize_filename
        # file name can be blank when assigning via file_url
        return if file.name.blank?
        self.file.name = file.name.split('.').map(&:parameterize).join('.')
      end
  end
end

# == Schema Information
#
# Table name: folio_files
#
#  id              :integer          not null, primary key
#  file_uid        :string
#  file_name       :string
#  type            :string
#  thumbnail_sizes :text             default("--- {}\n")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  file_size       :integer
#  mime_type       :string(255)
#  additional_data :json
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
