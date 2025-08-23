# frozen_string_literal: true

class Folio::FilePlacement::Image < Folio::FilePlacement::Base
  include Folio::Sitemap::FilePlacement::Image

  folio_image_placement :image_placements

  # Automatically inherit metadata from file when created
  before_validation :copy_metadata_from_file, on: :create
  
  private
  
  def copy_metadata_from_file
    return unless Rails.application.config.folio_image_metadata_copy_to_placements
    return unless file.is_a?(Folio::File::Image)
    
    # Copy basic metadata that placements support
    self.alt ||= file.alt || file.description
    self.title ||= file.title || file.headline
    
    # Could also copy to caption if placement has that field
    # self.caption ||= file.description if respond_to?(:caption=)
  end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id                   :bigint(8)        not null, primary key
#  placement_type       :string
#  placement_id         :bigint(8)
#  file_id              :bigint(8)
#  position             :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  type                 :string
#  title                :text
#  alt                  :string
#  placement_title      :string
#  placement_title_type :string
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_title                  (placement_title)
#  index_folio_file_placements_on_placement_title_type             (placement_title_type)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#  index_folio_file_placements_on_type                             (type)
#
