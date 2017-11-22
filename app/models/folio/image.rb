# frozen_string_literal: true

require_dependency 'folio/concerns/thumbnails'

module Folio
  class Image < Folio::File
    include Thumbnails

    paginates_per 11

    VALID_FORMATS = %w{jpeg png bmp gif}

    # Validations
    validates_property :format, of: :file, in: VALID_FORMATS

    # Callbacks
    before_destroy do
      DeleteThumbnailsJob.perform_later(self.thumbnail_sizes)
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
#  thumbnail_sizes :text             default({})
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
