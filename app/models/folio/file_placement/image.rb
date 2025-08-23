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
    
    # Copy metadata with precedence: IPTC fields > legacy fields > metadata compose
    copy_alt_text
    copy_title_text
    copy_caption_if_available
  end
  
  def copy_alt_text
    # Priority: placement alt > file description > file alt > headline > metadata compose
    return if alt.present?
    
    self.alt = file.description.presence || 
               file.alt.presence || 
               file.headline.presence ||
               file.metadata_compose(["Caption", "Description", "Abstract"])
  end
  
  def copy_title_text
    # Priority: placement title > file headline > file title > metadata compose
    return if title.present?
    
    self.title = file.headline.presence ||
                 file.title.presence ||
                 file.metadata_compose(["Headline", "Title"])
  end
  
  def copy_caption_if_available
    # Copy to caption field if placement supports it
    if respond_to?(:caption=) && caption.blank?
      self.caption = file.description.presence ||
                     file.metadata_compose(["Caption", "Description"])
    end
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
