# frozen_string_literal: true

require_dependency 'folio/concerns/taggable'

module Folio
  class File < ApplicationRecord
    include Taggable

    dragonfly_accessor :file

    # Relations
    has_many :file_placements, class_name: 'Folio::FilePlacement'

    # Validations
    validates :file, :type, presence: true

    def title
      file_name
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
#
# Indexes
#
#  index_folio_files_on_type  (type)
#
